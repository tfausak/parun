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
import qualified Pawl.Engine.Replay as Replay
import qualified Pawl.Play.SplitMix as SplitMix
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.MulliganDecision as MulliganDecision
import qualified Pawl.Types.OptionalDecision as OptionalDecision
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.SplitMix as SplitMix.Type

-- | A random answer to each prompt the protocol offers options for, over
-- 'Replay.defaultAnswer'. Never concedes.
--
-- Not implemented: a random answer to every other prompt (#5227).
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
  Prompt.ChooseManaSource _ _ sources -> fmap Just (SplitMix.pick sources)
  Prompt.ChooseX _ _ _ _ least greatest -> SplitMix.between least greatest
  Prompt.ChooseOptional {} -> SplitMix.pick (OptionalDecision.Exercises NonEmpty.:| [OptionalDecision.Declines])
  prompt -> pure (Replay.defaultAnswer prompt)

coin :: (Monad m) => State.StateT SplitMix.Type.SplitMix m Bool
coin = SplitMix.pick (True NonEmpty.:| [False])
