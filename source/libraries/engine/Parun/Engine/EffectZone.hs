-- CR 113.6m's "or effect" half, asked of an EFFECT: does it move the object the
-- ability is on out of a particular zone, and which zones? The ABILITY-level
-- readings that rule defines fold this over an ability's effects, one per kind
-- of ability: Parun.Engine.AbilityZone.zonesFunctionedIn takes the cost half
-- (Parun.Engine.AbilityZone.costZones) alongside it, and
-- Parun.Engine.Event.Trigger.zonesFunctionedIn has no cost half to take.
--
-- Here rather than in Parun.Engine.Cost because it is a classification of an
-- EFFECT and that module's whole contract is to be the sole casing home for a
-- CostComponent; Parun.Engine.ManaAbility is the precedent for the shape and for
-- the module boundary.
--
-- Casing on Effect here is not a breach of design.md section 1, for the reason
-- Parun.Engine.ManaAbility gives: the closed half may depend on a CLASSIFICATION
-- of effects, and this function is one. What stays forbidden is a case that acts
-- on WHICH effect it is, and every arm below answers the one question in the
-- type.
module Parun.Engine.EffectZone where

import Control.Applicative ((<|>))
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.Modal as Modal
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.DealDamage as DealDamage
import qualified Parun.Types.Designate as Designate
import Parun.Types.Effect (Effect)
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.ForEach as ForEach
import qualified Parun.Types.ForEachNumber as ForEachNumber
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Repeat as Repeat
import qualified Parun.Types.RepeatIf as RepeatIf
import qualified Parun.Types.SetClassLevel as SetClassLevel
import qualified Parun.Types.SetHalfLocked as SetHalfLocked
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import Parun.Types.Zone (Zone)

-- CR 113.6m's clauses taken together, over every zone an ability's cost or
-- effect moves its object out of: each one says the ability "functions only in
-- that zone", and every one applies. Nothing when no zone is named, leaving the
-- caller's default; that zone when all name the same one; the empty set,
-- functioning nowhere, when two name different zones.
conjoin :: Set.Set Zone -> Maybe (Set.Set Zone)
conjoin named
  | Set.null named = Nothing
  | Set.size named == 1 = Just named
  | otherwise = Just Set.empty

-- CR 113.6m: "an ability whose cost or effect specifies that it moves the object
-- it's on out of a particular zone". Empty for an effect that specifies no
-- such move, which leaves CR 113.6's own default in place -- the ability
-- functions on the battlefield.
--
-- TWO conditions, and both are the rule's own words. The effect has to name the
-- zone it moves the object out of, which is the origin Effect.MoveToZone
-- carries; and the object moved has to be "THE OBJECT IT'S ON", which is the
-- `itself` set this carries. An effect that moves some other object out of a
-- graveyard -- Raise Dead's target -- says nothing about where its own ability
-- functions, and naming a zone for it would strand every such ability in the
-- graveyard.
--
-- A SET rather than Parun.Engine.Binding.triggerSource alone, because CR 400.7
-- gives one card two names: a bearer whose own departure is what triggered the
-- ability is read as CR 113.7's source for its characteristics and as CR
-- 400.7e's `became` for anything done TO it, and only the caller knows which of
-- those is the same card here. Parun.Engine.Event.Trigger.zonesFunctionedIn is
-- what decides, off the condition; Parun.Engine.AbilityZone.zonesFunctionedIn
-- passes the source slot alone, an activation binding no event slot.
--
-- The origin is only ever consulted here, so a card file that states one on a
-- move of anything but its own source states something nothing reads. That is a
-- card-data error rather than a rules question, and it is inert: this function
-- answers empty for it, which is the same answer the effect had before.
--
-- The DELAYED ABILITIES the reading is against -- CR 113.6m's final sentence
-- needs the text an Effect.ArmDelayedTrigger stands for. An arm inside a quoted
-- ability carries it (Parun.Engine.Game.carriedDelayedAbility); any other names
-- it (Parun.Types.Face.delayedAbilities holds the payload). Every caller supplies
-- the map off the same characteristics the ability is read from
-- (PC.delayedAbilities), which is where Parun.Engine.Projection's
-- declaredDelayedAbility resolves the name at run time. Rule
-- 702's own roster
-- (Parun.Engine.Keyword.mintedDelayedAbilities) is unioned in BEHIND that map, the
-- order Parun.Engine.Resolve.Arms.Objects's ArmDelayedTrigger arm resolves a name in, so the two cannot
-- disagree about what a minted name stands for. A regression fence rather than a
-- proof: every move on that roster states no origin, so the walk answers empty
-- for each with or without it.
--
-- A SET, every zone the effect names: a compound effect's body, or a delayed
-- ability's effects, may name more than one, and CR 113.6m's "functions only in
-- that zone" holds for each, so the callers conjoin all of them.
zonesFunctionedFrom :: Set.Set SlotName.SlotName -> Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card)) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Set.Set Zone
zonesFunctionedFrom itself delayed = zonesFunctionedAgainst itself (Just (Map.union delayed Keyword.mintedDelayedAbilities))

-- zonesFunctionedFrom's walk, against exactly the map it is given -- and with no map
-- inside a delayed ability's own effects, where no arm is read at all.
zonesFunctionedAgainst :: Set.Set SlotName.SlotName -> Maybe (Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card))) -> Effect Card.Type.Card (GrantedAbility.GrantedAbility Card.Type.Card) -> Set.Set Zone
zonesFunctionedAgainst itself delayed effect = case effect of
  -- Only an InSlot naming one of the `itself` slots can be "the object it's on".
  -- A swept set is never one object, so no sweeping arm can be; a library's
  -- top card is one object, but it is named by POSITION rather than by that slot,
  -- so it cannot be one either, and a chosen card in a graveyard or a hand is
  -- named by a CHOICE among many, which is not "the object it's on" for the same
  -- reason -- and neither is a card chosen out of a bound group. All of them
  -- answer empty however the card file states the origin -- the same inert
  -- card-data error the note above describes for a move of somebody else's
  -- permanent.
  Effect.MoveToZone (MoveToZone.MkMoveToZone ref _ _ _ origin _ _) -> case ref of
    ObjectRef.InSlot slot -> if Set.member slot itself then foldMap Set.singleton origin else Set.empty
    ObjectRef.EachMatching _ -> Set.empty
    ObjectRef.EachCardInGraveyard {} -> Set.empty
    ObjectRef.EachCardInYourHand -> Set.empty
    ObjectRef.EachCardInHand {} -> Set.empty
    ObjectRef.EachCardInYourLibrary _ -> Set.empty
    ObjectRef.EachCardYouOwn _ -> Set.empty
    ObjectRef.EachCardInExiledPile _ -> Set.empty
    ObjectRef.EachCardEncodedOnSource {} -> Set.empty
    ObjectRef.EachSpell _ -> Set.empty
    ObjectRef.EachAbility _ -> Set.empty
    ObjectRef.EachOnStack _ -> Set.empty
    ObjectRef.EachPlayer -> Set.empty
    ObjectRef.EachOpponent -> Set.empty
    ObjectRef.ChosenPlayer -> Set.empty
    ObjectRef.Players _ -> Set.empty
    ObjectRef.TopOfLibrary {} -> Set.empty
    ObjectRef.TopOfLibraryUntil {} -> Set.empty
    ObjectRef.TopOfGraveyard _ -> Set.empty
    ObjectRef.ChosenCardInGraveyard {} -> Set.empty
    ObjectRef.ChosenCardInHand {} -> Set.empty
    ObjectRef.ChosenCardFromAmong {} -> Set.empty
    ObjectRef.EachCardFromAmong {} -> Set.empty
    ObjectRef.RandomCardInHand _ -> Set.empty
    ObjectRef.RandomCardInGraveyard _ -> Set.empty
    ObjectRef.RandomCardInLibrary _ -> Set.empty
    -- Randomness's pick among many, a chosen card's reason.
    ObjectRef.AtRandom _ -> Set.empty
    ObjectRef.ChosenPermanents _ -> Set.empty
    ObjectRef.AttachedToBound _ -> Set.empty
    -- The object may be in any zone by now.
    ObjectRef.FromAnywhere _ -> Set.empty
    -- CR 608.2f's one action on several objects moves the object it's on when
    -- any member names it: Sandman, Shifting Scoundrel's "return this card and
    -- target land card from your graveyard".
    ObjectRef.AllOf refs -> if any namesItself refs then foldMap Set.singleton origin else Set.empty
  Effect.DealDamage (DealDamage.MkDealDamage {}) -> Set.empty
  Effect.Fight {} -> Set.empty
  Effect.ModifyTarget {} -> Set.empty
  Effect.ChangeText {} -> Set.empty
  Effect.AddMana _ -> Set.empty
  Effect.Firebend _ -> Set.empty
  Effect.ActivateManaAbilities {} -> Set.empty
  Effect.MoveMana {} -> Set.empty
  Effect.Search {} -> Set.empty
  Effect.ExileAllGraveyards -> Set.empty
  Effect.Proliferate -> Set.empty
  Effect.Reroll -> Set.empty
  Effect.RerollStoredResults _ -> Set.empty
  Effect.ChooseCardName _ -> Set.empty
  Effect.ChooseQuality _ -> Set.empty
  Effect.FromOutsideTheGame _ -> Set.empty
  -- CR 608.2n: the spell exiles ITSELF, so this says nothing about where an
  -- ability functions -- and no ability can print it at all.
  Effect.ExileThisSpell -> Set.empty
  Effect.Bolster _ -> Set.empty
  Effect.Amass _ -> Set.empty
  Effect.Blight _ -> Set.empty
  Effect.Earthbend _ -> Set.empty
  Effect.Airbend _ -> Set.empty
  Effect.TemptWithTheRing -> Set.empty
  Effect.OpenAttraction -> Set.empty
  Effect.Planeswalk -> Set.empty
  Effect.ChaosEnsues -> Set.empty
  Effect.Abandon -> Set.empty
  Effect.ClaimPrize -> Set.empty
  Effect.Forage -> Set.empty
  Effect.Populate -> Set.empty
  Effect.TimeTravel -> Set.empty
  Effect.Recruit -> Set.empty
  Effect.Learn -> Set.empty
  Effect.Cloak {} -> Set.empty
  Effect.ManifestDread {} -> Set.empty
  Effect.Venture {} -> Set.empty
  Effect.ExileHandThenDraw -> Set.empty
  Effect.NoteManaSpent -> Set.empty
  Effect.PlayerSacrifices {} -> Set.empty
  Effect.Vote {} -> Set.empty
  Effect.Bid {} -> Set.empty
  Effect.RestartGame _ -> Set.empty
  Effect.ControlPlayerNextTurn _ -> Set.empty
  Effect.ControlPlayerThisResolution _ -> Set.empty
  Effect.Destroy {} -> Set.empty
  Effect.Sacrifice _ -> Set.empty
  Effect.TurnFaceDown _ -> Set.empty
  Effect.TurnFaceUp _ -> Set.empty
  Effect.RemoveFromCombat _ -> Set.empty
  Effect.BecomesBlocked _ -> Set.empty
  Effect.SwitchBlockers _ -> Set.empty
  Effect.ExchangeBlocks _ -> Set.empty
  Effect.Draw {} -> Set.empty
  Effect.Mill {} -> Set.empty
  Effect.Reveal {} -> Set.empty
  Effect.LookAt {} -> Set.empty
  Effect.ArrangeInLibrary {} -> Set.empty
  Effect.Scry {} -> Set.empty
  Effect.Surveil {} -> Set.empty
  Effect.Fateseal {} -> Set.empty
  Effect.Clash {} -> Set.empty
  Effect.AsYouCascade {} -> Set.empty
  Effect.Explore {} -> Set.empty
  Effect.Assemble {} -> Set.empty
  Effect.Connive {} -> Set.empty
  Effect.Discard {} -> Set.empty
  Effect.LoseLife {} -> Set.empty
  Effect.GainLife {} -> Set.empty
  Effect.ExchangeLifeTotals _ -> Set.empty
  Effect.ExchangeValues _ -> Set.empty
  Effect.ExchangeZones _ -> Set.empty
  -- CR 113.6m's zone is the battlefield, which CR 113.6 already makes a
  -- permanent's abilities' zone.
  Effect.ExchangeCardZones _ -> Set.empty
  Effect.SetLifeTotal {} -> Set.empty
  Effect.LoseGame {} -> Set.empty
  Effect.WinGame {} -> Set.empty
  Effect.DrawGame {} -> Set.empty
  Effect.RedistributeLifeTotals -> Set.empty
  Effect.IncreaseSpeed {} -> Set.empty
  Effect.DecreaseSpeed {} -> Set.empty
  Effect.Create {} -> Set.empty
  Effect.Conjure {} -> Set.empty
  Effect.CreateCopy {} -> Set.empty
  -- CR 707.4 changes a permanent's copiable values while it stays on the
  -- battlefield, so nothing leaves a zone and this functions from none.
  Effect.BecomeCopy {} -> Set.empty
  -- CR 707.10 mints a new object onto the stack; nothing the ability is on
  -- moves out of a zone.
  Effect.CopyStackObject {} -> Set.empty
  Effect.Replace {} -> Set.empty
  Effect.SkipPhase {} -> Set.empty
  -- CR 615.5's rider is not descended into, and the answer stands: the rider
  -- does not run as an effect of this ability at all, but from
  -- Parun.Engine.Resolve.Effect.runPreventionRider against the effect's own source, so
  -- nothing it does can be this ability moving "the object it's on".
  Effect.PreventNextDamage {} -> Set.empty
  Effect.PreventAllDamage {} -> Set.empty
  Effect.PreventNextDamageInstance {} -> Set.empty
  Effect.RedirectDamage {} -> Set.empty
  Effect.Counter {} -> Set.empty
  Effect.PutCounters {} -> Set.empty
  Effect.Divide {} -> Set.empty
  Effect.PutCountersFrom {} -> Set.empty
  Effect.RemoveCounters {} -> Set.empty
  Effect.RemoveCountersAmong {} -> Set.empty
  Effect.MoveCounters {} -> Set.empty
  Effect.GainPlayerCounters {} -> Set.empty
  Effect.RemovePlayerCounters {} -> Set.empty
  Effect.PayAnyEnergy _ -> Set.empty
  Effect.ChooseNumber _ -> Set.empty
  Effect.Tap _ -> Set.empty
  Effect.Untap _ -> Set.empty
  Effect.Unattach _ -> Set.empty
  Effect.Detain _ -> Set.empty
  Effect.Goad _ -> Set.empty
  Effect.Pair _ -> Set.empty
  Effect.GrantLookAtExiled _ -> Set.empty
  Effect.MakePlotted _ -> Set.empty
  Effect.MakeForetold _ -> Set.empty
  Effect.MakeWarped _ -> Set.empty
  Effect.DoesNotUntapNext _ -> Set.empty
  Effect.Transform _ -> Set.empty
  Effect.Convert _ -> Set.empty
  Effect.Flip _ -> Set.empty
  -- CR 113.6m asks which zone an ability functions FROM by where the object it is
  -- on moves. A meld moves the cards the ability NAMED, and the melding ability's
  -- own source is one of them only because an earlier instruction exiled it --
  -- that instruction is the move, and this one puts cards onto the battlefield
  -- from wherever they already are.
  Effect.Meld {} -> Set.empty
  Effect.PhaseOut _ -> Set.empty
  Effect.AddPhases _ -> Set.empty
  Effect.EndTurn -> Set.empty
  Effect.EndCombatPhase -> Set.empty
  Effect.GainControl (GainControl.MkGainControl {}) -> Set.empty
  Effect.ExchangeControl _ -> Set.empty
  -- CR 113.6m's final sentence: "the same is true if the effect of that ability
  -- creates a delayed triggered ability whose effect moves the object out of a
  -- particular zone". Prized Amalgam's "return this card from your graveyard to
  -- the battlefield tapped at the beginning of the next end step" is the printing
  -- it decides -- the arm is the ability's only zone-relevant content, so without
  -- this the Amalgam functions on the battlefield, where it can never do its work.
  --
  -- ONE LEVEL: the delayed ability's own effects are walked with NO map, so a
  -- delayed ability that arms a second one -- named or carried -- contributes
  -- nothing. The rule says "creates a delayed triggered ability whose effect
  -- moves the object", naming the created ability's effect and not what that in
  -- turn creates, and the missing map is also what makes this walk terminate on
  -- a card that arms itself.
  --
  -- Empty for a name neither a face nor rule 702 declares, which is a card-data
  -- error rather than a rules question: Parun.CardSpec's D4 dataflow lint rejects
  -- such a card, and the answer here is the same empty set the arm gave before.
  Effect.ArmDelayedTrigger arm ->
    case delayed of
      Nothing -> Set.empty
      Just named -> case Game.carriedDelayedAbility arm <|> Map.lookup (ArmDelayedTrigger.name arm) named of
        Nothing -> Set.empty
        Just ability -> foldMap (zonesFunctionedAgainst itself Nothing) (Modal.allEffects (TriggeredAbility.modal ability))
  Effect.AffectPlayers {} -> Set.empty
  Effect.RequireBlock {} -> Set.empty
  Effect.Prohibit {} -> Set.empty
  Effect.ForbidAttack {} -> Set.empty
  Effect.ForbidBeingBlocked {} -> Set.empty
  Effect.RequireAttack {} -> Set.empty
  Effect.CreateEmblem {} -> Set.empty
  Effect.BecomeMonarch {} -> Set.empty
  Effect.TakeTheInitiative {} -> Set.empty
  Effect.Designate (Designate.MkDesignate {}) -> Set.empty
  Effect.SetClassLevel (SetClassLevel.MkSetClassLevel _ _) -> Set.empty
  Effect.Unsuspect _ -> Set.empty
  Effect.SetHalfLocked (SetHalfLocked.MkSetHalfLocked {}) -> Set.empty
  Effect.CounterAndMark _ -> Set.empty
  Effect.BecomeProtector _ -> Set.empty
  Effect.Mentor _ -> Set.empty
  Effect.Exploit -> Set.empty
  Effect.GiveGift -> Set.empty
  Effect.ItBecomes _ -> Set.empty
  Effect.ExileHaunting {} -> Set.empty
  Effect.Attach _ -> Set.empty
  Effect.AttachAsThoughCreature _ -> Set.empty
  Effect.AttachTarget {} -> Set.empty
  Effect.AttachTargetToEach {} -> Set.empty
  Effect.AttachBound {} -> Set.empty
  Effect.AttachAll {} -> Set.empty
  Effect.PlaySubgame _ -> Set.empty
  Effect.ChoosePlayer _ -> Set.empty
  Effect.ChoosePlayerAtRandom _ -> Set.empty
  Effect.ChoosePermanents _ -> Set.empty
  Effect.ChooseSector _ -> Set.empty
  Effect.RollDie {} -> Set.empty
  Effect.FlipCoin {} -> Set.empty
  Effect.TakeExtraTurn {} -> Set.empty
  Effect.ShuffleIntoLibrary {} -> Set.empty
  Effect.Ante {} -> Set.empty
  Effect.PutSticker {} -> Set.empty
  Effect.SetOwner {} -> Set.empty
  Effect.ExchangeOwnership {} -> Set.empty
  Effect.Shuffle {} -> Set.empty
  Effect.OfferCast {} -> Set.empty
  Effect.OfferNamedCopy {} -> Set.empty
  Effect.OfferNotedCopy {} -> Set.empty
  -- CR 113.6m names a zone an ability FUNCTIONS in by moving its own object out
  -- of it. This opcode moves nothing -- it writes a permission onto objects an
  -- earlier effect already placed -- so it names no zone.
  Effect.GrantPlayFromExile {} -> Set.empty
  -- Descended into, unlike CR 615.5's rider above: rule 608.2f's body runs as
  -- part of THIS effect, so a move it states is a move this ability's effect
  -- states, and CR 113.6m reads it. The loop's own reference names the members
  -- and is never "the object it's on", so only the body can answer at all. No
  -- card in the pool writes such a body.
  Effect.ForEach (ForEach.MkForEach _ _ _ body _ _ _) -> foldMap (zonesFunctionedAgainst itself delayed) body
  Effect.ForEachNumber (ForEachNumber.MkForEachNumber _ _ body) -> foldMap (zonesFunctionedAgainst itself delayed) body
  Effect.Repeat (Repeat.MkRepeat _ body _) -> foldMap (zonesFunctionedAgainst itself delayed) body
  Effect.RepeatIf (RepeatIf.MkRepeatIf process _ ifHolds) -> foldMap (zonesFunctionedAgainst itself delayed) (process <> ifHolds)
  Effect.Heal _ -> Set.empty
  Effect.ChooseNewTargets _ -> Set.empty
  Effect.ChangeTargets _ -> Set.empty
  where
    -- InSlot naming an `itself` slot, alone or inside an AllOf.
    namesItself ref = case ref of
      ObjectRef.InSlot slot -> Set.member slot itself
      ObjectRef.AllOf refs -> any namesItself refs
      _ -> False
