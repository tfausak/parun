{-# LANGUAGE GADTs #-}

-- | The random bot: a seat that picks among what each prompt offers, each
-- option equally likely, and never reads the game.
module Pawl.Play.Bot where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Traversable as Traversable
import Numeric.Natural (Natural)
import qualified Pawl.Engine.Damage as Damage
import qualified Pawl.Engine.Replay as Replay
import qualified Pawl.Engine.Target as Target
import qualified Pawl.Play.SplitMix as SplitMix
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.Dividing as Dividing
import qualified Pawl.Types.MulliganDecision as MulliganDecision
import qualified Pawl.Types.OptionalDecision as OptionalDecision
import qualified Pawl.Types.PaymentDecision as PaymentDecision
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.SplitMix as SplitMix.Type

-- | Each prompt a Portal game reaches, answered with one of its legal answers,
-- each equally likely. Never concedes.
--
-- Not implemented: a random answer to every other prompt, which gets
-- 'Replay.defaultAnswer' (#5227).
bot :: (Monad m) => Answerer.Answerer (State.StateT SplitMix.Type.SplitMix m)
bot = Answerer.MkAnswerer $ \asked -> case Asked.prompt asked of
  Prompt.ChooseAction _ _ actions -> maybe (pure Action.Pass) SplitMix.pick (NonEmpty.nonEmpty actions)
  Prompt.DeclareMulligan {} -> SplitMix.pick (MulliganDecision.Keep NonEmpty.:| [MulliganDecision.Mulligan])
  Prompt.Bottom _ _ cards count -> fmap (List.genericTake count) (SplitMix.shuffle cards)
  Prompt.ChooseDiscard _ _ cards count -> fmap (List.genericTake count) (SplitMix.shuffle cards)
  Prompt.DeclareAttackers _ _ attackers -> Monad.filterM (const coin) attackers
  Prompt.DeclareBlockers _ _ blockers attackers ->
    fmap (Map.fromList . Maybe.catMaybes) . Traversable.for blockers $ \blocker ->
      fmap (fmap (\attacker -> (blocker, Set.singleton attacker))) (SplitMix.pick (Nothing NonEmpty.:| fmap Just attackers))
  Prompt.ChooseTargets _ _ _ slots -> traverse (\(count, legal) -> fmap (Set.fromList . List.genericTake count) (SplitMix.shuffle (Set.toList legal))) slots
  Prompt.ChooseManaSource _ _ _ sources -> fmap Just (SplitMix.pick sources)
  Prompt.ChooseExtraManaSource _ _ sources -> SplitMix.pick (Nothing NonEmpty.<| fmap Just sources)
  Prompt.ChooseManaToSpend _ _ units -> SplitMix.pick units
  Prompt.ChooseX _ _ _ _ least greatest -> SplitMix.between least greatest
  Prompt.ChooseOptional {} -> SplitMix.pick (OptionalDecision.Exercises NonEmpty.:| [OptionalDecision.Declines])
  Prompt.ChooseManaYield _ _ _ options -> SplitMix.pick options
  Prompt.ChooseCombatDamageOption {} -> SplitMix.pick (OptionalDecision.Exercises NonEmpty.:| [OptionalDecision.Declines])
  Prompt.OrderTriggers _ _ entries -> SplitMix.shuffle (zipWith const [0 ..] entries)
  -- CR 510.1c-e / 702.19b: every division whose gates this creature's own
  -- damage clears. Not implemented: a division leaning on another creature's
  -- damage in the same step, legal under CR 702.19b's last sentence (#5227).
  Prompt.AssignCombatDamage _ _ _ thresholds power ->
    maybe (pure (Replay.defaultAnswer (Asked.prompt asked))) SplitMix.pick . NonEmpty.nonEmpty $
      filter (\division -> Damage.tiersCleared thresholds division Set.empty division) (divisions (Map.keys thresholds) power)
  Prompt.Search _ _ cards most -> atMost most cards
  -- CR 601.2d / 115.7f: every division the prompt allows.
  Prompt.ChooseDivision _ _ _ dividing targets ->
    maybe (pure (Replay.defaultAnswer (Asked.prompt asked))) SplitMix.pick . NonEmpty.nonEmpty $
      filter (Target.divides dividing targets) (divisions (NonEmpty.toList targets) (Dividing.total dividing))
  Prompt.ChooseToPay {} -> SplitMix.pick (PaymentDecision.Declines NonEmpty.:| [PaymentDecision.Pays])
  prompt -> pure (Replay.defaultAnswer prompt)

-- | CR 103.1: whether the bot, picked to choose who plays first, plays first
-- rather than draws, each equally likely.
playsFirst :: (Monad m) => State.StateT SplitMix.Type.SplitMix m Bool
playsFirst = coin

-- | A subset of at most so many of the items, each such subset equally
-- likely: its size drawn by how many subsets have it, then its members.
atMost :: (Monad m) => Natural -> [a] -> State.StateT SplitMix.Type.SplitMix m [a]
atMost most items = do
  let total = List.genericLength items :: Natural
      sizes = [0 .. min most total]
      weights = fmap (choose total) sizes
  draw <- SplitMix.between 0 (sum weights - 1)
  let size = maybe 0 fst (List.find ((> draw) . snd) (zip sizes (scanl1 (+) weights)))
  fmap (List.genericTake size) (SplitMix.shuffle items)
  where
    choose n k = product [n - k + 1 .. n] `div` product [1 .. k]

-- | Every way to divide an amount among the keys, zero shares left out.
divisions :: (Ord k) => [k] -> Natural -> [Map.Map k Natural]
divisions keys amount = case keys of
  [] -> [Map.empty | amount == 0]
  key : rest -> do
    share <- [0 .. amount]
    fmap (if share == 0 then id else Map.insert key share) (divisions rest (amount - share))

coin :: (Monad m) => State.StateT SplitMix.Type.SplitMix m Bool
coin = SplitMix.pick (True NonEmpty.:| [False])
