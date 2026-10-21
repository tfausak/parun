{-# LANGUAGE GADTs #-}
{-# LANGUAGE RankNTypes #-}

-- The one loop every answerer plugs into: a prompt is routed to the
-- answerer for its seat, observers watch it either side of the answer, and a
-- game is stepped until it ends or its caller says stop.
module Pawl.Engine.Driver where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import Numeric.Natural (Natural)
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Observer as Observer
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Result as Result

-- | A prompt whose seat has an answerer goes to it; every other prompt, chance
-- included, goes to the fallback.
bySeat :: Map.Map PlayerId.PlayerId (Answerer.Answerer m) -> Answerer.Answerer m -> Answerer.Answerer m
bySeat seats fallback = Answerer.MkAnswerer $ \asked ->
  let answerer = Maybe.fromMaybe fallback (deciderOf (Asked.prompt asked) >>= (`Map.lookup` seats))
   in Answerer.unwrap answerer asked

-- | Every observer's before, in order, then the answer, then every observer's
-- after, in order.
ask :: (Monad m) => [Observer.Observer m] -> Answerer.Answerer m -> Asked.Asked r -> m r
ask observers answerer asked = do
  mapM_ (\observer -> Observer.before observer asked) observers
  answer <- Answerer.unwrap answerer asked
  mapM_ (\observer -> Observer.after observer asked answer) observers
  pure answer

-- | A whole game, from setup to its result.
match :: (Monad m) => [Observer.Observer m] -> Answerer.Answerer m -> GameSettings.GameSettings -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> m (Result.Result, GameState.GameState)
match observers answerer settings matchup =
  Engine.runGameAsked (ask observers answerer) (Setup.gameWith settings (fmap fst matchup)) (Engine.playFrom matchup)

-- | Whole steps (CR 500.1) from a state, until the game has a result, the
-- budget is spent, or the predicate holds.
drive :: (Monad m) => [Observer.Observer m] -> Answerer.Answerer m -> Natural -> (GameState.GameState -> m Bool) -> GameState.GameState -> m GameState.GameState
drive observers answerer budget stop gs = do
  stopping <- stop gs
  if budget == 0 || Maybe.isJust (GameState.result gs) || stopping
    then pure gs
    else do
      (_, next) <- Engine.runGameAsked (ask observers answerer) gs Engine.runStep
      drive observers answerer (budget - 1) stop next

-- WHO ANSWERS a prompt: the Decider it carries, which CR 723.5 makes the seat
-- that makes every choice a controlled player would make. Not the PlayerId the
-- prompt is about; the two differ only while CR 723.1's effect is running.
-- Prompt.Concede is the exception CR 723.6 names and answers with its own seat,
-- and the random and shuffle prompts answer Nothing -- randomness is not a
-- choice, so no seat makes it.
--
-- Total on purpose: a hand-kept catalog over a GADT this size drifts silently,
-- and the wildcard that would let it drift is what -Wincomplete-patterns is here
-- to refuse.
deciderOf :: Prompt.Prompt r -> Maybe PlayerId.PlayerId
deciderOf prompt = case prompt of
  Prompt.ChooseAction decider _ _ -> Just (Decider.unwrap decider)
  Prompt.Concede pid -> Just pid
  Prompt.Shuffle {} -> Nothing
  Prompt.RandomFirstPlayer {} -> Nothing
  Prompt.RandomObject {} -> Nothing
  Prompt.RandomStickerSheet {} -> Nothing
  Prompt.RandomPlayer {} -> Nothing
  Prompt.RandomCard {} -> Nothing
  Prompt.ChooseConjuredCard decider _ _ -> Just (Decider.unwrap decider)
  Prompt.RollDie {} -> Nothing
  Prompt.RandomDepth {} -> Nothing
  Prompt.LookUpCard {} -> Nothing
  Prompt.ReferenceCards {} -> Nothing
  Prompt.ReferenceNames {} -> Nothing
  Prompt.ChooseDieResult decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.FlipCoin {} -> Nothing
  Prompt.CallCoin decider _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCoinResult decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDiscard decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseScry decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseSurveil decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseFateseal decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseExplore decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.RerollDie decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.AdjustDieRoll decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRollModifier decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDefender decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseManaSource decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseExtraManaSource decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ReverseManaAbilities decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseManaYield decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseManaToSpend decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseProliferate decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRedistribution decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRingBearer decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseBolster decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseAmass decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseBlight decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseBehold decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCounterRemoval decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCounterRemovalAmong decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCounterRemovalAtLeast decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCounterRemovalUpTo decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCounterDistribution decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDivision decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseMixedCounterRemoval decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseVote decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCounterKind decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseMovedCounters decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseStoredRerolls decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseMovedCountersAtLeastOne decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDistributedMovedCounters decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseMovedCounterOrNone decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChoosePaidEnergy decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseNumber decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseReadAheadChapter decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDamageSource decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDelayedTriggerEvent decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCardInGraveyard decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCardInHand decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCardFromAmong decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseAnyNumber decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDungeon decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseSticker decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseStickerOrNone decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseNamePosition decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCompanion decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseFromOutsideTheGame decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRoom decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseHalf decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseLegend decider _ _ -> Just (Decider.unwrap decider)
  Prompt.DeclareAttackers decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseAttackTarget decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseExert decider _ _ -> Just (Decider.unwrap decider)
  Prompt.DeclareBlockers decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.AssignCombatDamage decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseTargets decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.AnnounceTargets decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseLandTypeSwap decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCreatureTypeSwap decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseEnchantmentTypeSwap decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseBasicLandType decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCreatureType decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseSearchZones decider _ _ -> Just (Decider.unwrap decider)
  Prompt.Search decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.CastWhileSearching decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseX decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseMutateSide decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseForage decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseLearn decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseTimeTravel decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseClash decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseEntwine decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseBuyback decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseSplice decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseAssistant decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseAssistAmount decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseKicker decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ReturnCommander decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCommandZoneOfferFirst decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseLibraryEnd decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ArrangeLibraryArrivals decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ArrangeLibraryCards decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ArrangeGraveyardArrivals decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseModes decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCopyTarget decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseEntryOption decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRiot decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseUnleash decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseTribute decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDredge decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRedirect decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseSubstitute decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChoosePayLifeOnEntry decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRevealOnEntry decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseEnlist decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseEncode decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseColor decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseDesignation decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseManaType decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCardName decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseOpponent decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseProtector decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChoosePlayer decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseActivePlayer decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderTriggers decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderDamage decider _ _ -> Just (Decider.unwrap decider)
  Prompt.AllocateDamage decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseReplacement decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseSacrifices decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseExilesFromGraveyard decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseMaterials decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCollectEvidence decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChoosePermanent decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseTapsForTotalPower decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseTaps decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseReturns decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseExiles decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseAttachment decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseTurnUpAttachment decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseCost decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChoosePlayPermission decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderCostComponents decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderCombatTolls decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderComponentCards decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseStickerKeeper decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderForEach decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseLoopMembers decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseRepeat decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderTimestamps decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OrderManaActivations decider _ _ -> Just (Decider.unwrap decider)
  Prompt.DeclareMulligan decider _ _ -> Just (Decider.unwrap decider)
  Prompt.Bottom decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.MulliganAction decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OpeningHandAction decider _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseOptional decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseClause decider _ _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.OfferedCast decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseOfferedCastSpell decider _ _ -> Just (Decider.unwrap decider)
  Prompt.OfferedMiracleReveal decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.OfferedExtra decider _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseToPay decider _ _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.AnnouncePhyrexianPayment decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.AnnounceHybridPayment decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.AnnounceHybridHalf decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseReductionHalf decider _ _ _ _ -> Just (Decider.unwrap decider)
  Prompt.ChooseReducedCost decider _ _ _ -> Just (Decider.unwrap decider)
