{-# LANGUAGE GADTs #-}

-- | The random bot: a seat that picks among what each prompt offers, each
-- option equally likely, and never reads its view of the game.
module Parun.Play.Bot where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Traversable as Traversable
import Numeric.Natural (Natural)
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Engine.Damage as Damage
import qualified Parun.Engine.Modal as Modal
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Subtype as Subtype
import qualified Parun.Engine.Target as Target
import qualified Parun.Engine.TextWord as TextWord
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Play.SplitMix as SplitMix
import qualified Parun.Types.Action as Action
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CoinFace as CoinFace
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.Dividing as Dividing
import qualified Parun.Types.GuessAnswer as GuessAnswer
import qualified Parun.Types.MulliganDecision as MulliganDecision
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.PaymentDecision as PaymentDecision
import qualified Parun.Types.PlayerView as PlayerView
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.SplitMix as SplitMix.Type
import qualified Parun.Types.TargetCount as TargetCount

-- | Each prompt a bot game over the decks in data/decks reaches, plus
-- ChooseGuess, ChooseNumber and the prompts sharing an arm's shape, answered
-- with one of its legal answers, each equally likely, an unbounded number
-- capped one past its floor. Never concedes. A card name is any of `names`,
-- the reference's (Parun.Play.Game.bot).
--
-- Not implemented: a random answer to every other prompt, which gets
-- 'Replay.defaultAnswer': one of a list (#6597), a fixed decision or a bounded
-- number (#6598), a group, piles or an order (#6599), and a division of
-- counters or an amount (#6600).
bot :: (Monad m) => [CardName.CardName] -> Answerer.Answerer (Asked.Asked PlayerView.PlayerView) (State.StateT SplitMix.Type.SplitMix m)
bot names = Answerer.MkAnswerer $ \asked -> case Asked.prompt asked of
  Prompt.ChooseAction _ _ actions -> maybe (pure Action.Pass) SplitMix.pick (NonEmpty.nonEmpty actions)
  Prompt.DeclareMulligan {} -> SplitMix.pick (MulliganDecision.Keep NonEmpty.:| [MulliganDecision.Mulligan])
  Prompt.Bottom _ _ cards count -> fmap (List.genericTake count) (SplitMix.shuffle cards)
  Prompt.ChooseDiscard _ _ cards count -> fmap (List.genericTake count) (SplitMix.shuffle cards)
  Prompt.DeclareAttackers _ _ attackers -> Monad.filterM (const coin) attackers
  -- CR 508.1e / 702.22c: any disjoint bands of the attackers; the engine drops
  -- a band the rules do not allow (Parun.Engine.Combat's legalBand).
  Prompt.DeclareBands _ _ attackers -> fmap (List.sort . fmap Set.fromList . filter ((> 1) . length)) (partition attackers)
  Prompt.ChooseAttackTarget _ _ _ targets -> SplitMix.pick targets
  Prompt.DeclareBlockers _ _ blockers attackers ->
    fmap (Map.fromList . Maybe.catMaybes) . Traversable.for blockers $ \blocker ->
      fmap (fmap (\attacker -> (blocker, Set.singleton attacker))) (SplitMix.pick (Nothing NonEmpty.:| fmap Just attackers))
  Prompt.ChooseTargets _ _ _ slots -> traverse (\(count, legal) -> fmap (Set.fromList . List.genericTake count) (SplitMix.shuffle (Set.toList legal))) slots
  Prompt.ChooseManaSource _ _ _ sources -> fmap Just (SplitMix.pick sources)
  Prompt.ChooseExtraManaSource _ _ sources -> SplitMix.pick (Nothing NonEmpty.<| fmap Just sources)
  Prompt.ChooseManaToSpend _ _ units -> SplitMix.pick units
  Prompt.ChooseManaSpentOnX _ _ _ shares -> SplitMix.pick shares
  Prompt.ChooseX _ _ _ _ least greatest -> SplitMix.between least greatest
  Prompt.ChooseOptional {} -> exercisesOrDeclines
  Prompt.PayLifeForMana {} -> exercisesOrDeclines
  Prompt.ChooseManaYield _ _ _ options -> SplitMix.pick options
  Prompt.ChooseTurnMarker _ _ markers -> SplitMix.pick markers
  Prompt.ChooseCombatDamageOption {} -> exercisesOrDeclines
  Prompt.OrderTriggers _ _ entries -> order entries
  Prompt.OrderTimestamps _ _ objects -> order objects
  Prompt.OrderManaActivations _ _ objects -> order objects
  Prompt.OrderCombatTolls _ _ objects -> order objects
  Prompt.OrderComponentCards _ _ _ printings -> order printings
  Prompt.OrderCostComponents _ _ _ components -> order components
  Prompt.OrderDamage _ _ events -> order events
  Prompt.OrderForEach _ _ _ recipients -> order recipients
  Prompt.ArrangeLibraryCards _ _ objects -> order objects
  Prompt.ArrangeLibraryArrivals _ _ _ objects -> order objects
  -- CR 701.22a / 701.25a / 701.29a: any of the cards to the bottom (the
  -- graveyard, surveilling), the rest on top, each in any order.
  Prompt.ChooseScry _ _ cards -> split cards
  Prompt.ChooseSurveil _ _ cards -> split cards
  Prompt.ChooseFateseal _ _ _ cards -> split cards
  -- CR 700.2: every selection the instruction allows over the legal modes.
  Prompt.ChooseModes _ _ _ legal selection -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (Modal.selections legal selection)
  -- CR 601.2c: each slot's count from its floor to what the board supplies.
  Prompt.AnnounceTargets _ _ _ offers -> traverse (\(count, legal) -> SplitMix.between (TargetCount.least count) (TargetCount.ceilingOn (Natural.length legal) count)) offers
  Prompt.ReverseManaAbilities {} -> exercisesOrDeclines
  Prompt.ChooseDamageSource _ _ _ candidates -> SplitMix.pick candidates
  Prompt.ChooseCardInHand _ _ _ candidates -> SplitMix.pick candidates
  Prompt.ChooseColor _ _ _ colors -> SplitMix.pick colors
  Prompt.ChooseManaType _ _ _ types -> SplitMix.pick types
  -- CR 205.3m / 305.6: any creature type, any of the five basic land types.
  Prompt.ChooseCreatureType {} -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter Subtype.isCreatureType [minBound ..])
  Prompt.ChooseBasicLandType {} -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter Subtype.isBasicLandType [minBound ..])
  -- The printed "and/or": any nonempty group of the places.
  Prompt.ChooseSearchZones _ _ places -> someOf places
  Prompt.ChooseCost _ _ _ candidates _ -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) candidates
  Prompt.CallCoin {} -> SplitMix.pick (CoinFace.Heads NonEmpty.:| [CoinFace.Tails])
  -- CR 615.7: every share of the shield, each event taking at most its own
  -- damage (Parun.Engine.Replacement.askAllocation's gate).
  Prompt.AllocateDamage _ _ events share -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (allocations (fmap DamageEvent.amount events) share)
  Prompt.ChooseTaps _ _ _ candidates count -> fmap (Set.fromList . List.genericTake count) (SplitMix.shuffle candidates)
  Prompt.ChooseReturns _ _ _ candidates count -> fmap (Set.fromList . List.genericTake count) (SplitMix.shuffle candidates)
  Prompt.ChooseExiles _ _ _ candidates count -> fmap (Set.fromList . List.genericTake count) (SplitMix.shuffle candidates)
  Prompt.OfferedCast {} -> exercisesOrDeclines
  -- Each of these is a "may" or an either-or, both answers always legal.
  Prompt.ChooseCommandZoneOfferFirst {} -> exercisesOrDeclines
  Prompt.ChooseDredge {} -> exercisesOrDeclines
  Prompt.ChooseExert {} -> exercisesOrDeclines
  Prompt.ChooseExplore {} -> exercisesOrDeclines
  Prompt.ChoosePayLifeOnEntry {} -> exercisesOrDeclines
  Prompt.ChooseRedirect {} -> exercisesOrDeclines
  Prompt.ChooseRepeat {} -> exercisesOrDeclines
  Prompt.ChooseRiot {} -> exercisesOrDeclines
  Prompt.ChooseSubstitute {} -> exercisesOrDeclines
  Prompt.ChooseTribute {} -> exercisesOrDeclines
  Prompt.ChooseTurnUpAttachment {} -> exercisesOrDeclines
  Prompt.ChooseUnleash {} -> exercisesOrDeclines
  Prompt.OfferedExtra {} -> exercisesOrDeclines
  Prompt.OfferedMiracleReveal {} -> exercisesOrDeclines
  Prompt.RerollDie {} -> exercisesOrDeclines
  Prompt.ChooseOfferedCastSpell _ _ options -> SplitMix.pick options
  -- CR 707.5: any candidate, or the card's "may" declined.
  Prompt.ChooseCopyTarget _ _ _ candidates -> SplitMix.pick (Nothing NonEmpty.:| fmap Just candidates)
  Prompt.ChooseAnyNumber _ _ _ _ candidates most _ -> fmap Set.fromList (atMost (Maybe.fromMaybe (List.genericLength candidates) most) candidates)
  -- CR 510.1c-e / 702.19b: every division whose gates this creature's own
  -- damage clears. Not implemented: a division leaning on another creature's
  -- damage in the same step, legal under CR 702.19b's third sentence (#6601).
  Prompt.AssignCombatDamage _ _ _ thresholds power ->
    pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter (\division -> Damage.tiersCleared thresholds division Set.empty division) (divisions (Map.keys thresholds) power))
  Prompt.Search _ _ cards most -> atMost most cards
  -- CR 601.2d / 115.7f: every division the prompt allows.
  Prompt.ChooseDivision _ _ _ dividing targets ->
    pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter (Target.divides dividing targets) (divisions (NonEmpty.toList targets) (Dividing.total dividing)))
  Prompt.ChooseToPay {} -> SplitMix.pick (PaymentDecision.Declines NonEmpty.:| [PaymentDecision.Pays])
  Prompt.ChoosePermanent _ _ _ candidates _ -> SplitMix.pick candidates
  Prompt.ChooseCardFromAmong _ _ _ candidates -> SplitMix.pick candidates
  Prompt.ChooseSacrifices _ _ _ candidates count _ -> fmap (Set.fromList . List.genericTake count) (SplitMix.shuffle candidates)
  -- CR 118.1 / 601.2h / 608.2d: any bearer, then any division of its
  -- counters the count allows, each within what its permanent carries.
  Prompt.ChooseCounterRemoval _ _ _ candidates -> SplitMix.pick candidates
  Prompt.ChooseCounterRemovalAmong _ _ _ owed offered -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter (Cost.dividesRemoval owed offered) (removals offered))
  Prompt.ChooseCounterRemovalAtLeast _ _ _ least offered -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter (Cost.dividesRemovalAtLeast least offered) (removals offered))
  Prompt.ChooseCounterRemovalUpTo _ _ _ most offered -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (filter ((<= most) . sum) (removals offered))
  -- CR 608.2d: any branch left to choose, or neither where each branch
  -- carries its own decline.
  Prompt.ChooseClause _ _ _ _ branches neither _ -> SplitMix.pick ((if neither then (Nothing NonEmpty.<|) else id) (fmap Just branches))
  Prompt.ChooseGuess {} -> SplitMix.pick (GuessAnswer.Holds NonEmpty.:| [GuessAnswer.DoesNotHold])
  -- CR 107.1c: an unbounded number, a bid's included, reaches one past its
  -- floor, so a bid tops the high bid by one or declines.
  Prompt.ChooseNumber _ _ _ least _ greatest -> SplitMix.between least (Maybe.fromMaybe (least + 1) greatest)
  -- CR 612.2: any two different words of a family the text change names.
  Prompt.ChooseWordSwap _ _ _ _ families forbidden -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) (TextWord.swaps families forbidden)
  -- CR 201.4: any name; CR 201.4a's restriction is judged where the
  -- reference is (Parun.Interpreter.policingCardNames), which asks again.
  Prompt.ChooseCardName {} -> pickOr (Replay.defaultAnswer (Asked.prompt asked)) names
  prompt -> pure (Replay.defaultAnswer prompt)

-- | Any of the options, each equally likely, or the fallback where there is
-- none.
pickOr :: (Monad m) => a -> [a] -> State.StateT SplitMix.Type.SplitMix m a
pickOr fallback = maybe (pure fallback) SplitMix.pick . NonEmpty.nonEmpty

-- | Every division of the offered counters, each permanent giving from none
-- to all it carries, zero shares left out.
removals :: (Ord k) => Map.Map k Natural -> [Map.Map k Natural]
removals offered = fmap (Map.filter (> 0) . Map.fromList) (traverse (\(key, carried) -> fmap ((,) key) [0 .. carried]) (Map.toList offered))

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

-- | A partition of the items into nonempty blocks, each partition equally
-- likely: the first item's companions drawn by how many partitions they
-- leave, then the rest partitioned alike.
partition :: (Monad m) => [a] -> State.StateT SplitMix.Type.SplitMix m [[a]]
partition items = case items of
  [] -> pure []
  first : rest -> do
    let others = List.genericLength rest :: Natural
        counts = [0 .. others]
        weights = fmap (\k -> choose others k * bell (others - k)) counts
    draw <- SplitMix.between 0 (sum weights - 1)
    let companions = maybe 0 fst (List.find ((> draw) . snd) (zip counts (scanl1 (+) weights)))
    shuffled <- SplitMix.shuffle rest
    let (block, remaining) = List.genericSplitAt companions shuffled
    fmap ((first : block) :) (partition remaining)

-- | How many ways to choose k of n.
choose :: Natural -> Natural -> Natural
choose n k = product [n - k + 1 .. n] `div` product [1 .. k]

-- | How many partitions a set of n items has.
bell :: Natural -> Natural
bell = List.genericIndex bells
  where
    bells = 1 : fmap (\n -> sum (zipWith (\k b -> choose n k * b) [0 .. n] bells)) [0 ..]

-- | A permutation of the items' indices, each equally likely.
order :: (Monad m) => [a] -> State.StateT SplitMix.Type.SplitMix m [Natural]
order items = SplitMix.shuffle (zipWith const [0 ..] items)

-- | The items in any order, cut at any point, each such answer equally likely.
split :: (Monad m) => [a] -> State.StateT SplitMix.Type.SplitMix m ([a], [a])
split items = do
  shuffled <- SplitMix.shuffle items
  at <- SplitMix.between 0 (List.genericLength items)
  pure (List.genericSplitAt at shuffled)

-- | A nonempty subset of the items, each equally likely; empty only when the
-- items are.
someOf :: (Monad m, Ord a) => Set.Set a -> State.StateT SplitMix.Type.SplitMix m (Set.Set a)
someOf items = do
  chosen <- fmap Set.fromList (Monad.filterM (const coin) (Set.toList items))
  if Set.null chosen && not (Set.null items) then someOf items else pure chosen

-- | Every way to spend the whole amount over the caps, each share within its
-- own.
allocations :: [Natural] -> Natural -> [[Natural]]
allocations caps amount = case caps of
  [] -> [[] | amount == 0]
  cap : rest -> do
    share <- [0 .. min cap amount]
    fmap (share :) (allocations rest (amount - share))

-- | Every way to divide an amount among the keys, zero shares left out.
divisions :: (Ord k) => [k] -> Natural -> [Map.Map k Natural]
divisions keys amount = case keys of
  [] -> [Map.empty | amount == 0]
  key : rest -> do
    share <- [0 .. amount]
    fmap (if share == 0 then id else Map.insert key share) (divisions rest (amount - share))

-- | A "may" taken or declined, each equally likely.
exercisesOrDeclines :: (Monad m) => State.StateT SplitMix.Type.SplitMix m OptionalDecision.OptionalDecision
exercisesOrDeclines = SplitMix.pick (OptionalDecision.Exercises NonEmpty.:| [OptionalDecision.Declines])

coin :: (Monad m) => State.StateT SplitMix.Type.SplitMix m Bool
coin = SplitMix.pick (True NonEmpty.:| [False])
