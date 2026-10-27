-- | Where the effect knot is tied. The card codec is a PARAMETER, so this module
-- names no concrete card type; Parun.Codec.Card passes its own codec in.
--
-- RECURSIVE five times over: PreventNextDamage's CR 615.5 rider, PreventAllDamage's
-- rider under the same rule, the same rule's rider on a Replace's DamageR, and
-- ForEach's CR 608.2f body all hold effects, and CreateEmblem's payload is a whole
-- card whose faces hold effects. Each names 'codec' inside its own definition, which
-- terminates for Parun.Codec.TriggerCondition's
-- reason -- 'Arm.tagged' reaches WHNF without forcing its arm list, and
-- 'Define.define' registers the type's name before running the schema body.
--
-- Casing on an effect's identity here is open-half machinery, not the rules core.
module Parun.Codec.Effect where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ActivateManaAbilities as ActivateManaAbilities
import qualified Parun.Codec.AffectPlayers as AffectPlayers
import qualified Parun.Codec.Amass as Amass
import qualified Parun.Codec.Ante as Ante
import qualified Parun.Codec.ArmDelayedTrigger as ArmDelayedTrigger
import qualified Parun.Codec.ArrangeInLibrary as ArrangeInLibrary
import qualified Parun.Codec.AttachAll as AttachAll
import qualified Parun.Codec.AttachBound as AttachBound
import qualified Parun.Codec.AttachTarget as AttachTarget
import qualified Parun.Codec.BecomeCopy as BecomeCopy
import qualified Parun.Codec.Bid as Bid
import qualified Parun.Codec.BindAmount as BindAmount
import qualified Parun.Codec.Blight as Blight
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CastOffer as CastOffer
import qualified Parun.Codec.ChangeText as ChangeText
import qualified Parun.Codec.ChooseCardName as ChooseCardName
import qualified Parun.Codec.ChooseNumber as ChooseNumber
import qualified Parun.Codec.ChoosePermanents as ChoosePermanents
import qualified Parun.Codec.ChoosePlayer as ChoosePlayer
import qualified Parun.Codec.ChoosePlayerAtRandom as ChoosePlayerAtRandom
import qualified Parun.Codec.ChosenQuality as ChosenQuality
import qualified Parun.Codec.Conjure as Conjure
import qualified Parun.Codec.Connive as Connive
import qualified Parun.Codec.ControlPlayer as ControlPlayer
import qualified Parun.Codec.ControlSides as ControlSides
import qualified Parun.Codec.CopyStackObject as CopyStackObject
import qualified Parun.Codec.Counter as Counter
import qualified Parun.Codec.Create as Create
import qualified Parun.Codec.CreateCopy as CreateCopy
import qualified Parun.Codec.Daytime as Daytime
import qualified Parun.Codec.DealDamage as DealDamage
import qualified Parun.Codec.Designate as Designate
import qualified Parun.Codec.Destroy as Destroy
import qualified Parun.Codec.Discard as Discard
import qualified Parun.Codec.Divide as Divide
import qualified Parun.Codec.DoesNotUntapNext as DoesNotUntapNext
import qualified Parun.Codec.Draw as Draw
import qualified Parun.Codec.Earthbend as Earthbend
import qualified Parun.Codec.ExchangeBlocks as ExchangeBlocks
import qualified Parun.Codec.ExchangeCardZones as ExchangeCardZones
import qualified Parun.Codec.ExchangeOwnership as ExchangeOwnership
import qualified Parun.Codec.ExchangeSides as ExchangeSides
import qualified Parun.Codec.ExchangeValues as ExchangeValues
import qualified Parun.Codec.ExchangeZones as ExchangeZones
import qualified Parun.Codec.ExileHaunting as ExileHaunting
import qualified Parun.Codec.ExtraPhase as ExtraPhase
import qualified Parun.Codec.Fight as Fight
import qualified Parun.Codec.FlipCoin as FlipCoin
import qualified Parun.Codec.ForEach as ForEach
import qualified Parun.Codec.ForEachNumber as ForEachNumber
import qualified Parun.Codec.ForbidAttack as ForbidAttack
import qualified Parun.Codec.ForbidBeingBlocked as ForbidBeingBlocked
import qualified Parun.Codec.FromOutsideTheGame as FromOutsideTheGame
import qualified Parun.Codec.GainControl as GainControl
import qualified Parun.Codec.GrantLookAtExiled as GrantLookAtExiled
import qualified Parun.Codec.GrantPlayFromExile as GrantPlayFromExile
import qualified Parun.Codec.InitiativeTarget as InitiativeTarget
import qualified Parun.Codec.LifeLoss as LifeLoss
import qualified Parun.Codec.LookAt as LookAt
import qualified Parun.Codec.MakeForetold as MakeForetold
import qualified Parun.Codec.ManaAddition as ManaAddition
import qualified Parun.Codec.Meld as Meld
import qualified Parun.Codec.Mill as Mill
import qualified Parun.Codec.ModifyTarget as ModifyTarget
import qualified Parun.Codec.MonarchTarget as MonarchTarget
import qualified Parun.Codec.MoveCounters as MoveCounters
import qualified Parun.Codec.MoveMana as MoveMana
import qualified Parun.Codec.MoveToZone as MoveToZone
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.OfferCast as OfferCast
import qualified Parun.Codec.PermanentActed as PermanentActed
import qualified Parun.Codec.PlayerCounters as PlayerCounters
import qualified Parun.Codec.PlayerQuantity as PlayerQuantity
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.PlayerSacrifices as PlayerSacrifices
import qualified Parun.Codec.PreventAllDamage as PreventAllDamage
import qualified Parun.Codec.PreventNextDamage as PreventNextDamage
import qualified Parun.Codec.PreventNextDamageInstance as PreventNextDamageInstance
import qualified Parun.Codec.Prohibit as Prohibit
import qualified Parun.Codec.PutCounters as PutCounters
import qualified Parun.Codec.PutCountersFrom as PutCountersFrom
import qualified Parun.Codec.PutSticker as PutSticker
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.RedirectDamage as RedirectDamage
import qualified Parun.Codec.RemoveCounters as RemoveCounters
import qualified Parun.Codec.RemoveCountersAmong as RemoveCountersAmong
import qualified Parun.Codec.RemovePlayerCounters as RemovePlayerCounters
import qualified Parun.Codec.Repeat as Repeat
import qualified Parun.Codec.RepeatIf as RepeatIf
import qualified Parun.Codec.Replace as Replace
import qualified Parun.Codec.RequireAttack as RequireAttack
import qualified Parun.Codec.RequireBlock as RequireBlock
import qualified Parun.Codec.Reveal as Reveal
import qualified Parun.Codec.RollDie as RollDie
import qualified Parun.Codec.SacrificeEffect as SacrificeEffect
import qualified Parun.Codec.Search as Search
import qualified Parun.Codec.SetClassLevel as SetClassLevel
import qualified Parun.Codec.SetHalfLocked as SetHalfLocked
import qualified Parun.Codec.SetOwner as SetOwner
import qualified Parun.Codec.ShuffleIntoLibrary as ShuffleIntoLibrary
import qualified Parun.Codec.SkipPhase as SkipPhase
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.SpeedDecrease as SpeedDecrease
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.Codec.TakeExtraTurn as TakeExtraTurn
import qualified Parun.Codec.Tap as Tap
import qualified Parun.Codec.TurnFaceDown as TurnFaceDown
import qualified Parun.Codec.Vote as Vote
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Effect as Effect

codec :: (Typeable.Typeable card, Eq card, Typeable.Typeable ability, Eq ability) => Codec.Codec card -> Codec.Codec ability -> Codec.Codec (Effect.Effect card ability)
codec cardCodec abilityCodec =
  let createCodec = Create.codec cardCodec abilityCodec
      conjureCodec = Conjure.codec cardCodec
      meldCodec = Meld.codec cardCodec
      replaceCodec = Replace.codec cardCodec abilityCodec (codec cardCodec abilityCodec)
      preventCodec = PreventNextDamage.codec (codec cardCodec abilityCodec)
      preventAllCodec = PreventAllDamage.codec (codec cardCodec abilityCodec)
      preventInstanceCodec = PreventNextDamageInstance.codec (codec cardCodec abilityCodec)
      forEachCodec = ForEach.codec (codec cardCodec abilityCodec)
      forEachNumberCodec = ForEachNumber.codec (codec cardCodec abilityCodec)
      repeatCodec = Repeat.codec (codec cardCodec abilityCodec)
      repeatIfCodec = RepeatIf.codec (codec cardCodec abilityCodec)
   in Arm.tagged
        tagOf
        [ Arm.payload "DealDamage" DealDamage.codec Effect.DealDamage (\x -> case x of Effect.DealDamage y -> Just y; _ -> Nothing),
          Arm.payload "ModifyTarget" (ModifyTarget.codec abilityCodec) Effect.ModifyTarget (\x -> case x of Effect.ModifyTarget y -> Just y; _ -> Nothing),
          Arm.payload "ChangeText" ChangeText.codec Effect.ChangeText (\x -> case x of Effect.ChangeText y -> Just y; _ -> Nothing),
          Arm.payload "AddMana" ManaAddition.codec Effect.AddMana (\x -> case x of Effect.AddMana y -> Just y; _ -> Nothing),
          Arm.payload "ActivateManaAbilities" ActivateManaAbilities.codec Effect.ActivateManaAbilities (\x -> case x of Effect.ActivateManaAbilities y -> Just y; _ -> Nothing),
          Arm.payload "MoveMana" MoveMana.codec Effect.MoveMana (\x -> case x of Effect.MoveMana y -> Just y; _ -> Nothing),
          Arm.payload "Search" Search.codec Effect.Search (\x -> case x of Effect.Search y -> Just y; _ -> Nothing),
          Arm.nullary "ExileAllGraveyards" Effect.ExileAllGraveyards,
          Arm.nullary "Proliferate" Effect.Proliferate,
          Arm.nullary "Reroll" Effect.Reroll,
          Arm.payload "RerollStoredResults" SlotName.codec Effect.RerollStoredResults (\x -> case x of Effect.RerollStoredResults y -> Just y; _ -> Nothing),
          Arm.payload "ChooseCardName" ChooseCardName.codec Effect.ChooseCardName (\x -> case x of Effect.ChooseCardName y -> Just y; _ -> Nothing),
          Arm.payload "ChooseQuality" ChosenQuality.codec Effect.ChooseQuality (\x -> case x of Effect.ChooseQuality y -> Just y; _ -> Nothing),
          Arm.payload "FromOutsideTheGame" FromOutsideTheGame.codec Effect.FromOutsideTheGame (\x -> case x of Effect.FromOutsideTheGame y -> Just y; _ -> Nothing),
          Arm.nullary "ExileThisSpell" Effect.ExileThisSpell,
          Arm.payload "Bolster" Quantity.codec Effect.Bolster (\x -> case x of Effect.Bolster y -> Just y; _ -> Nothing),
          Arm.payload "Amass" Amass.codec Effect.Amass (\x -> case x of Effect.Amass y -> Just y; _ -> Nothing),
          Arm.payload "Blight" Blight.codec Effect.Blight (\x -> case x of Effect.Blight y -> Just y; _ -> Nothing),
          Arm.nullary "TemptWithTheRing" Effect.TemptWithTheRing,
          Arm.nullary "OpenAttraction" Effect.OpenAttraction,
          Arm.payload "Assemble" (Common.maybe ObjectRef.codec) Effect.Assemble (\x -> case x of Effect.Assemble y -> Just y; _ -> Nothing),
          Arm.nullary "Planeswalk" Effect.Planeswalk,
          Arm.nullary "ChaosEnsues" Effect.ChaosEnsues,
          Arm.nullary "Abandon" Effect.Abandon,
          Arm.nullary "ClaimPrize" Effect.ClaimPrize,
          Arm.nullary "Forage" Effect.Forage,
          Arm.nullary "Populate" Effect.Populate,
          Arm.nullary "TimeTravel" Effect.TimeTravel,
          Arm.nullary "Recruit" Effect.Recruit,
          Arm.nullary "Learn" Effect.Learn,
          Arm.payload "Cloak" PlayerRef.codec Effect.Cloak (\x -> case x of Effect.Cloak y -> Just y; _ -> Nothing),
          Arm.payload "ManifestDread" PlayerRef.codec Effect.ManifestDread (\x -> case x of Effect.ManifestDread y -> Just y; _ -> Nothing),
          Arm.optionalPayload "Venture" Subtype.codec Effect.Venture (\x -> case x of Effect.Venture y -> Just y; _ -> Nothing),
          Arm.nullary "ExileHandThenDraw" Effect.ExileHandThenDraw,
          Arm.nullary "NoteManaSpent" Effect.NoteManaSpent,
          Arm.payload "PlayerSacrifices" PlayerSacrifices.codec Effect.PlayerSacrifices (\x -> case x of Effect.PlayerSacrifices y -> Just y; _ -> Nothing),
          Arm.payload "Vote" Vote.codec Effect.Vote (\x -> case x of Effect.Vote y -> Just y; _ -> Nothing),
          Arm.payload "Bid" Bid.codec Effect.Bid (\x -> case x of Effect.Bid y -> Just y; _ -> Nothing),
          Arm.optionalPayload "RestartGame" ObjectRef.codec Effect.RestartGame (\x -> case x of Effect.RestartGame y -> Just y; _ -> Nothing),
          Arm.payload "ControlPlayerNextTurn" SlotName.codec Effect.ControlPlayerNextTurn (\x -> case x of Effect.ControlPlayerNextTurn y -> Just y; _ -> Nothing),
          Arm.payload "ControlPlayerThisResolution" ControlPlayer.codec Effect.ControlPlayerThisResolution (\x -> case x of Effect.ControlPlayerThisResolution y -> Just y; _ -> Nothing),
          Arm.payload "Destroy" Destroy.codec Effect.Destroy (\x -> case x of Effect.Destroy y -> Just y; _ -> Nothing),
          Arm.payload "Fight" Fight.codec Effect.Fight (\x -> case x of Effect.Fight y -> Just y; _ -> Nothing),
          Arm.payload "Sacrifice" SacrificeEffect.codec Effect.Sacrifice (\x -> case x of Effect.Sacrifice y -> Just y; _ -> Nothing),
          Arm.payload "TurnFaceDown" (TurnFaceDown.codec abilityCodec) Effect.TurnFaceDown (\x -> case x of Effect.TurnFaceDown y -> Just y; _ -> Nothing),
          Arm.payload "TurnFaceUp" SlotName.codec Effect.TurnFaceUp (\x -> case x of Effect.TurnFaceUp y -> Just y; _ -> Nothing),
          Arm.payload "RemoveFromCombat" ObjectRef.codec Effect.RemoveFromCombat (\x -> case x of Effect.RemoveFromCombat y -> Just y; _ -> Nothing),
          Arm.payload "BecomesBlocked" SlotName.codec Effect.BecomesBlocked (\x -> case x of Effect.BecomesBlocked y -> Just y; _ -> Nothing),
          Arm.payload "SwitchBlockers" SlotName.codec Effect.SwitchBlockers (\x -> case x of Effect.SwitchBlockers y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeBlocks" ExchangeBlocks.codec Effect.ExchangeBlocks (\x -> case x of Effect.ExchangeBlocks y -> Just y; _ -> Nothing),
          Arm.payload "Counter" Counter.codec Effect.Counter (\x -> case x of Effect.Counter y -> Just y; _ -> Nothing),
          Arm.payload "MoveToZone" (MoveToZone.codec abilityCodec) Effect.MoveToZone (\x -> case x of Effect.MoveToZone y -> Just y; _ -> Nothing),
          Arm.payload "Draw" Draw.codec Effect.Draw (\x -> case x of Effect.Draw y -> Just y; _ -> Nothing),
          Arm.payload "Reveal" Reveal.codec Effect.Reveal (\x -> case x of Effect.Reveal y -> Just y; _ -> Nothing),
          Arm.payload "LookAt" LookAt.codec Effect.LookAt (\x -> case x of Effect.LookAt y -> Just y; _ -> Nothing),
          Arm.payload "Scry" PlayerQuantity.codec Effect.Scry (\x -> case x of Effect.Scry y -> Just y; _ -> Nothing),
          Arm.payload "Surveil" PlayerQuantity.codec Effect.Surveil (\x -> case x of Effect.Surveil y -> Just y; _ -> Nothing),
          Arm.payload "Fateseal" PlayerQuantity.codec Effect.Fateseal (\x -> case x of Effect.Fateseal y -> Just y; _ -> Nothing),
          Arm.payload "Clash" SlotName.codec Effect.Clash (\x -> case x of Effect.Clash y -> Just y; _ -> Nothing),
          Arm.payload "AsYouCascade" SlotName.codec Effect.AsYouCascade (\x -> case x of Effect.AsYouCascade y -> Just y; _ -> Nothing),
          Arm.payload "Explore" ObjectRef.codec Effect.Explore (\x -> case x of Effect.Explore y -> Just y; _ -> Nothing),
          Arm.payload "ArrangeInLibrary" ArrangeInLibrary.codec Effect.ArrangeInLibrary (\x -> case x of Effect.ArrangeInLibrary y -> Just y; _ -> Nothing),
          Arm.payload "Connive" Connive.codec Effect.Connive (\x -> case x of Effect.Connive y -> Just y; _ -> Nothing),
          Arm.payload "Mill" Mill.codec Effect.Mill (\x -> case x of Effect.Mill y -> Just y; _ -> Nothing),
          Arm.payload "Discard" Discard.codec Effect.Discard (\x -> case x of Effect.Discard y -> Just y; _ -> Nothing),
          Arm.payload "LoseLife" LifeLoss.codec Effect.LoseLife (\x -> case x of Effect.LoseLife y -> Just y; _ -> Nothing),
          Arm.payload "GainLife" PlayerQuantity.codec Effect.GainLife (\x -> case x of Effect.GainLife y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeLifeTotals" ExchangeSides.codec Effect.ExchangeLifeTotals (\x -> case x of Effect.ExchangeLifeTotals y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeValues" ExchangeValues.codec Effect.ExchangeValues (\x -> case x of Effect.ExchangeValues y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeZones" ExchangeZones.codec Effect.ExchangeZones (\x -> case x of Effect.ExchangeZones y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeCardZones" ExchangeCardZones.codec Effect.ExchangeCardZones (\x -> case x of Effect.ExchangeCardZones y -> Just y; _ -> Nothing),
          Arm.payload "SetLifeTotal" PlayerQuantity.codec Effect.SetLifeTotal (\x -> case x of Effect.SetLifeTotal y -> Just y; _ -> Nothing),
          Arm.payload "LoseGame" PlayerRef.codec Effect.LoseGame (\x -> case x of Effect.LoseGame y -> Just y; _ -> Nothing),
          Arm.payload "WinGame" PlayerRef.codec Effect.WinGame (\x -> case x of Effect.WinGame y -> Just y; _ -> Nothing),
          Arm.nullary "DrawGame" Effect.DrawGame,
          Arm.nullary "RedistributeLifeTotals" Effect.RedistributeLifeTotals,
          Arm.payload "IncreaseSpeed" PlayerQuantity.codec Effect.IncreaseSpeed (\x -> case x of Effect.IncreaseSpeed y -> Just y; _ -> Nothing),
          Arm.payload "DecreaseSpeed" SpeedDecrease.codec Effect.DecreaseSpeed (\x -> case x of Effect.DecreaseSpeed y -> Just y; _ -> Nothing),
          Arm.payload "Create" createCodec Effect.Create (\x -> case x of Effect.Create y -> Just y; _ -> Nothing),
          Arm.payload "Conjure" conjureCodec Effect.Conjure (\x -> case x of Effect.Conjure y -> Just y; _ -> Nothing),
          Arm.payload "CreateCopy" (CreateCopy.codec abilityCodec) Effect.CreateCopy (\x -> case x of Effect.CreateCopy y -> Just y; _ -> Nothing),
          Arm.payload "CopyStackObject" (CopyStackObject.codec abilityCodec) Effect.CopyStackObject (\x -> case x of Effect.CopyStackObject y -> Just y; _ -> Nothing),
          Arm.payload "BecomeCopy" (BecomeCopy.codec abilityCodec) Effect.BecomeCopy (\x -> case x of Effect.BecomeCopy y -> Just y; _ -> Nothing),
          Arm.payload "Replace" replaceCodec Effect.Replace (\x -> case x of Effect.Replace y -> Just y; _ -> Nothing),
          Arm.payload "SkipPhase" SkipPhase.codec Effect.SkipPhase (\x -> case x of Effect.SkipPhase y -> Just y; _ -> Nothing),
          Arm.payload "PreventNextDamage" preventCodec Effect.PreventNextDamage (\x -> case x of Effect.PreventNextDamage y -> Just y; _ -> Nothing),
          Arm.payload "PreventAllDamage" preventAllCodec Effect.PreventAllDamage (\x -> case x of Effect.PreventAllDamage y -> Just y; _ -> Nothing),
          Arm.payload "PreventNextDamageInstance" preventInstanceCodec Effect.PreventNextDamageInstance (\x -> case x of Effect.PreventNextDamageInstance y -> Just y; _ -> Nothing),
          Arm.payload "RedirectDamage" RedirectDamage.codec Effect.RedirectDamage (\x -> case x of Effect.RedirectDamage y -> Just y; _ -> Nothing),
          Arm.payload "PutCounters" PutCounters.codec Effect.PutCounters (\x -> case x of Effect.PutCounters y -> Just y; _ -> Nothing),
          Arm.payload "Divide" Divide.codec Effect.Divide (\x -> case x of Effect.Divide y -> Just y; _ -> Nothing),
          Arm.payload "MoveCounters" MoveCounters.codec Effect.MoveCounters (\x -> case x of Effect.MoveCounters y -> Just y; _ -> Nothing),
          Arm.payload "PutCountersFrom" PutCountersFrom.codec Effect.PutCountersFrom (\x -> case x of Effect.PutCountersFrom y -> Just y; _ -> Nothing),
          Arm.payload "RemoveCounters" RemoveCounters.codec Effect.RemoveCounters (\x -> case x of Effect.RemoveCounters y -> Just y; _ -> Nothing),
          Arm.payload "RemoveCountersAmong" RemoveCountersAmong.codec Effect.RemoveCountersAmong (\x -> case x of Effect.RemoveCountersAmong y -> Just y; _ -> Nothing),
          Arm.payload "GainPlayerCounters" PlayerCounters.codec Effect.GainPlayerCounters (\x -> case x of Effect.GainPlayerCounters y -> Just y; _ -> Nothing),
          Arm.payload "RemovePlayerCounters" RemovePlayerCounters.codec Effect.RemovePlayerCounters (\x -> case x of Effect.RemovePlayerCounters y -> Just y; _ -> Nothing),
          Arm.payload "PayAnyEnergy" SlotName.codec Effect.PayAnyEnergy (\x -> case x of Effect.PayAnyEnergy y -> Just y; _ -> Nothing),
          Arm.payload "ChooseNumber" ChooseNumber.codec Effect.ChooseNumber (\x -> case x of Effect.ChooseNumber y -> Just y; _ -> Nothing),
          Arm.payload "BindAmount" BindAmount.codec Effect.BindAmount (\x -> case x of Effect.BindAmount y -> Just y; _ -> Nothing),
          Arm.payload "Tap" Tap.codec Effect.Tap (\x -> case x of Effect.Tap y -> Just y; _ -> Nothing),
          Arm.payload "Untap" ObjectRef.codec Effect.Untap (\x -> case x of Effect.Untap y -> Just y; _ -> Nothing),
          Arm.payload "Unattach" ObjectRef.codec Effect.Unattach (\x -> case x of Effect.Unattach y -> Just y; _ -> Nothing),
          Arm.payload "Detain" ObjectRef.codec Effect.Detain (\x -> case x of Effect.Detain y -> Just y; _ -> Nothing),
          Arm.payload "Earthbend" Earthbend.codec Effect.Earthbend (\x -> case x of Effect.Earthbend y -> Just y; _ -> Nothing),
          Arm.payload "Airbend" ObjectRef.codec Effect.Airbend (\x -> case x of Effect.Airbend y -> Just y; _ -> Nothing),
          Arm.payload "Goad" ObjectRef.codec Effect.Goad (\x -> case x of Effect.Goad y -> Just y; _ -> Nothing),
          Arm.payload "Pair" ObjectRef.codec Effect.Pair (\x -> case x of Effect.Pair y -> Just y; _ -> Nothing),
          Arm.payload "DoesNotUntapNext" DoesNotUntapNext.codec Effect.DoesNotUntapNext (\x -> case x of Effect.DoesNotUntapNext y -> Just y; _ -> Nothing),
          Arm.payload "Transform" ObjectRef.codec Effect.Transform (\x -> case x of Effect.Transform y -> Just y; _ -> Nothing),
          Arm.payload "Convert" ObjectRef.codec Effect.Convert (\x -> case x of Effect.Convert y -> Just y; _ -> Nothing),
          Arm.payload "Flip" ObjectRef.codec Effect.Flip (\x -> case x of Effect.Flip y -> Just y; _ -> Nothing),
          Arm.payload "Meld" meldCodec Effect.Meld (\x -> case x of Effect.Meld y -> Just y; _ -> Nothing),
          Arm.payload "PhaseOut" ObjectRef.codec Effect.PhaseOut (\x -> case x of Effect.PhaseOut y -> Just y; _ -> Nothing),
          Arm.payload "AddPhases" (Common.list ExtraPhase.codec) Effect.AddPhases (\x -> case x of Effect.AddPhases y -> Just y; _ -> Nothing),
          Arm.nullary "EndTurn" Effect.EndTurn,
          Arm.nullary "EndCombatPhase" Effect.EndCombatPhase,
          Arm.payload "GainControl" GainControl.codec Effect.GainControl (\x -> case x of Effect.GainControl y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeControl" ControlSides.codec Effect.ExchangeControl (\x -> case x of Effect.ExchangeControl y -> Just y; _ -> Nothing),
          Arm.payload "ArmDelayedTrigger" (ArmDelayedTrigger.codec abilityCodec) Effect.ArmDelayedTrigger (\x -> case x of Effect.ArmDelayedTrigger y -> Just y; _ -> Nothing),
          Arm.payload "AffectPlayers" AffectPlayers.codec Effect.AffectPlayers (\x -> case x of Effect.AffectPlayers y -> Just y; _ -> Nothing),
          Arm.payload "RequireBlock" RequireBlock.codec Effect.RequireBlock (\x -> case x of Effect.RequireBlock y -> Just y; _ -> Nothing),
          Arm.payload "RequireAttack" RequireAttack.codec Effect.RequireAttack (\x -> case x of Effect.RequireAttack y -> Just y; _ -> Nothing),
          Arm.payload "Prohibit" Prohibit.codec Effect.Prohibit (\x -> case x of Effect.Prohibit y -> Just y; _ -> Nothing),
          Arm.payload "ForbidAttack" ForbidAttack.codec Effect.ForbidAttack (\x -> case x of Effect.ForbidAttack y -> Just y; _ -> Nothing),
          Arm.payload "ForbidBeingBlocked" ForbidBeingBlocked.codec Effect.ForbidBeingBlocked (\x -> case x of Effect.ForbidBeingBlocked y -> Just y; _ -> Nothing),
          Arm.payload "CreateEmblem" cardCodec Effect.CreateEmblem (\x -> case x of Effect.CreateEmblem y -> Just y; _ -> Nothing),
          Arm.payload "BecomeMonarch" MonarchTarget.codec Effect.BecomeMonarch (\x -> case x of Effect.BecomeMonarch y -> Just y; _ -> Nothing),
          Arm.payload "TakeTheInitiative" InitiativeTarget.codec Effect.TakeTheInitiative (\x -> case x of Effect.TakeTheInitiative y -> Just y; _ -> Nothing),
          Arm.payload "Designate" Designate.codec Effect.Designate (\x -> case x of Effect.Designate y -> Just y; _ -> Nothing),
          Arm.payload "SetClassLevel" SetClassLevel.codec Effect.SetClassLevel (\x -> case x of Effect.SetClassLevel y -> Just y; _ -> Nothing),
          Arm.payload "Unsuspect" ObjectRef.codec Effect.Unsuspect (\x -> case x of Effect.Unsuspect y -> Just y; _ -> Nothing),
          Arm.payload "SetHalfLocked" SetHalfLocked.codec Effect.SetHalfLocked (\x -> case x of Effect.SetHalfLocked y -> Just y; _ -> Nothing),
          Arm.payload "CounterAndMark" (PermanentActed.codec SlotName.codec) Effect.CounterAndMark (\x -> case x of Effect.CounterAndMark y -> Just y; _ -> Nothing),
          Arm.payload "BecomeProtector" SlotName.codec Effect.BecomeProtector (\x -> case x of Effect.BecomeProtector y -> Just y; _ -> Nothing),
          Arm.payload "Mentor" SlotName.codec Effect.Mentor (\x -> case x of Effect.Mentor y -> Just y; _ -> Nothing),
          Arm.nullary "Exploit" Effect.Exploit,
          Arm.nullary "GiveGift" Effect.GiveGift,
          Arm.payload "Firebend" ManaAddition.codec Effect.Firebend (\x -> case x of Effect.Firebend y -> Just y; _ -> Nothing),
          Arm.payload "ItBecomes" Daytime.codec Effect.ItBecomes (\x -> case x of Effect.ItBecomes y -> Just y; _ -> Nothing),
          Arm.payload "ExileHaunting" ExileHaunting.codec Effect.ExileHaunting (\x -> case x of Effect.ExileHaunting y -> Just y; _ -> Nothing),
          Arm.payload "Attach" SlotName.codec Effect.Attach (\x -> case x of Effect.Attach y -> Just y; _ -> Nothing),
          Arm.payload "AttachAsThoughCreature" SlotName.codec Effect.AttachAsThoughCreature (\x -> case x of Effect.AttachAsThoughCreature y -> Just y; _ -> Nothing),
          Arm.payload "AttachTarget" AttachTarget.codec Effect.AttachTarget (\x -> case x of Effect.AttachTarget y -> Just y; _ -> Nothing),
          Arm.payload "AttachTargetToEach" AttachTarget.codec Effect.AttachTargetToEach (\x -> case x of Effect.AttachTargetToEach y -> Just y; _ -> Nothing),
          Arm.payload "AttachBound" AttachBound.codec Effect.AttachBound (\x -> case x of Effect.AttachBound y -> Just y; _ -> Nothing),
          Arm.payload "AttachAll" AttachAll.codec Effect.AttachAll (\x -> case x of Effect.AttachAll y -> Just y; _ -> Nothing),
          Arm.payload "PlaySubgame" SlotName.codec Effect.PlaySubgame (\x -> case x of Effect.PlaySubgame y -> Just y; _ -> Nothing),
          Arm.payload "ChoosePlayer" ChoosePlayer.codec Effect.ChoosePlayer (\x -> case x of Effect.ChoosePlayer y -> Just y; _ -> Nothing),
          Arm.payload "ChoosePlayerAtRandom" ChoosePlayerAtRandom.codec Effect.ChoosePlayerAtRandom (\x -> case x of Effect.ChoosePlayerAtRandom y -> Just y; _ -> Nothing),
          Arm.payload "ChoosePermanents" ChoosePermanents.codec Effect.ChoosePermanents (\x -> case x of Effect.ChoosePermanents y -> Just y; _ -> Nothing),
          Arm.payload "ChooseSector" SlotName.codec Effect.ChooseSector (\x -> case x of Effect.ChooseSector y -> Just y; _ -> Nothing),
          Arm.payload "RollDie" RollDie.codec Effect.RollDie (\x -> case x of Effect.RollDie y -> Just y; _ -> Nothing),
          Arm.payload "FlipCoin" FlipCoin.codec Effect.FlipCoin (\x -> case x of Effect.FlipCoin y -> Just y; _ -> Nothing),
          Arm.payload "TakeExtraTurn" TakeExtraTurn.codec Effect.TakeExtraTurn (\x -> case x of Effect.TakeExtraTurn y -> Just y; _ -> Nothing),
          Arm.payload "ShuffleIntoLibrary" ShuffleIntoLibrary.codec Effect.ShuffleIntoLibrary (\x -> case x of Effect.ShuffleIntoLibrary y -> Just y; _ -> Nothing),
          Arm.payload "Ante" Ante.codec Effect.Ante (\x -> case x of Effect.Ante y -> Just y; _ -> Nothing),
          Arm.payload "PutSticker" PutSticker.codec Effect.PutSticker (\x -> case x of Effect.PutSticker y -> Just y; _ -> Nothing),
          Arm.payload "SetOwner" SetOwner.codec Effect.SetOwner (\x -> case x of Effect.SetOwner y -> Just y; _ -> Nothing),
          Arm.payload "ExchangeOwnership" ExchangeOwnership.codec Effect.ExchangeOwnership (\x -> case x of Effect.ExchangeOwnership y -> Just y; _ -> Nothing),
          Arm.payload "Shuffle" PlayerRef.codec Effect.Shuffle (\x -> case x of Effect.Shuffle y -> Just y; _ -> Nothing),
          Arm.payload "OfferCast" OfferCast.codec Effect.OfferCast (\x -> case x of Effect.OfferCast y -> Just y; _ -> Nothing),
          Arm.payload "OfferNamedCopy" (Common.nonEmpty CardName.codec) Effect.OfferNamedCopy (\x -> case x of Effect.OfferNamedCopy y -> Just y; _ -> Nothing),
          Arm.payload "OfferNotedCopy" CastOffer.codec Effect.OfferNotedCopy (\x -> case x of Effect.OfferNotedCopy y -> Just y; _ -> Nothing),
          Arm.payload "GrantPlayFromExile" GrantPlayFromExile.codec Effect.GrantPlayFromExile (\x -> case x of Effect.GrantPlayFromExile y -> Just y; _ -> Nothing),
          Arm.payload "GrantLookAtExiled" GrantLookAtExiled.codec Effect.GrantLookAtExiled (\x -> case x of Effect.GrantLookAtExiled y -> Just y; _ -> Nothing),
          Arm.payload "MakePlotted" ObjectRef.codec Effect.MakePlotted (\x -> case x of Effect.MakePlotted y -> Just y; _ -> Nothing),
          Arm.payload "MakeForetold" MakeForetold.codec Effect.MakeForetold (\x -> case x of Effect.MakeForetold y -> Just y; _ -> Nothing),
          Arm.payload "MakeWarped" ObjectRef.codec Effect.MakeWarped (\x -> case x of Effect.MakeWarped y -> Just y; _ -> Nothing),
          Arm.payload "ForEach" forEachCodec Effect.ForEach (\x -> case x of Effect.ForEach y -> Just y; _ -> Nothing),
          Arm.payload "ForEachNumber" forEachNumberCodec Effect.ForEachNumber (\x -> case x of Effect.ForEachNumber y -> Just y; _ -> Nothing),
          Arm.payload "Repeat" repeatCodec Effect.Repeat (\x -> case x of Effect.Repeat y -> Just y; _ -> Nothing),
          Arm.payload "RepeatIf" repeatIfCodec Effect.RepeatIf (\x -> case x of Effect.RepeatIf y -> Just y; _ -> Nothing),
          Arm.payload "Heal" ObjectRef.codec Effect.Heal (\x -> case x of Effect.Heal y -> Just y; _ -> Nothing),
          Arm.payload "ChooseNewTargets" ObjectRef.codec Effect.ChooseNewTargets (\x -> case x of Effect.ChooseNewTargets y -> Just y; _ -> Nothing),
          Arm.payload "ChangeTargets" ObjectRef.codec Effect.ChangeTargets (\x -> case x of Effect.ChangeTargets y -> Just y; _ -> Nothing)
        ]

tagOf :: Effect.Effect card ability -> String
tagOf x = case x of
  Effect.DealDamage {} -> "DealDamage"
  Effect.ModifyTarget {} -> "ModifyTarget"
  Effect.ChangeText {} -> "ChangeText"
  Effect.AddMana {} -> "AddMana"
  Effect.ActivateManaAbilities {} -> "ActivateManaAbilities"
  Effect.MoveMana {} -> "MoveMana"
  Effect.Search {} -> "Search"
  Effect.ExileAllGraveyards {} -> "ExileAllGraveyards"
  Effect.Proliferate {} -> "Proliferate"
  Effect.Reroll {} -> "Reroll"
  Effect.RerollStoredResults {} -> "RerollStoredResults"
  Effect.ChooseCardName {} -> "ChooseCardName"
  Effect.ChooseQuality {} -> "ChooseQuality"
  Effect.FromOutsideTheGame {} -> "FromOutsideTheGame"
  Effect.ExileThisSpell {} -> "ExileThisSpell"
  Effect.Bolster {} -> "Bolster"
  Effect.Amass {} -> "Amass"
  Effect.Blight {} -> "Blight"
  Effect.TemptWithTheRing {} -> "TemptWithTheRing"
  Effect.OpenAttraction {} -> "OpenAttraction"
  Effect.Assemble {} -> "Assemble"
  Effect.Planeswalk {} -> "Planeswalk"
  Effect.ChaosEnsues {} -> "ChaosEnsues"
  Effect.Abandon {} -> "Abandon"
  Effect.ClaimPrize {} -> "ClaimPrize"
  Effect.Forage {} -> "Forage"
  Effect.Populate {} -> "Populate"
  Effect.TimeTravel {} -> "TimeTravel"
  Effect.Recruit {} -> "Recruit"
  Effect.Learn {} -> "Learn"
  Effect.Cloak {} -> "Cloak"
  Effect.ManifestDread {} -> "ManifestDread"
  Effect.Venture {} -> "Venture"
  Effect.ExileHandThenDraw {} -> "ExileHandThenDraw"
  Effect.NoteManaSpent {} -> "NoteManaSpent"
  Effect.PlayerSacrifices {} -> "PlayerSacrifices"
  Effect.Vote {} -> "Vote"
  Effect.Bid {} -> "Bid"
  Effect.RestartGame {} -> "RestartGame"
  Effect.ControlPlayerNextTurn {} -> "ControlPlayerNextTurn"
  Effect.ControlPlayerThisResolution {} -> "ControlPlayerThisResolution"
  Effect.Destroy {} -> "Destroy"
  Effect.Fight {} -> "Fight"
  Effect.Sacrifice {} -> "Sacrifice"
  Effect.TurnFaceDown {} -> "TurnFaceDown"
  Effect.TurnFaceUp {} -> "TurnFaceUp"
  Effect.RemoveFromCombat {} -> "RemoveFromCombat"
  Effect.BecomesBlocked {} -> "BecomesBlocked"
  Effect.SwitchBlockers {} -> "SwitchBlockers"
  Effect.ExchangeBlocks {} -> "ExchangeBlocks"
  Effect.Counter {} -> "Counter"
  Effect.MoveToZone {} -> "MoveToZone"
  Effect.Draw {} -> "Draw"
  Effect.Reveal {} -> "Reveal"
  Effect.LookAt {} -> "LookAt"
  Effect.Scry {} -> "Scry"
  Effect.Surveil {} -> "Surveil"
  Effect.Fateseal {} -> "Fateseal"
  Effect.Clash {} -> "Clash"
  Effect.AsYouCascade {} -> "AsYouCascade"
  Effect.Explore {} -> "Explore"
  Effect.ArrangeInLibrary {} -> "ArrangeInLibrary"
  Effect.Connive {} -> "Connive"
  Effect.Mill {} -> "Mill"
  Effect.Discard {} -> "Discard"
  Effect.LoseLife {} -> "LoseLife"
  Effect.GainLife {} -> "GainLife"
  Effect.ExchangeLifeTotals {} -> "ExchangeLifeTotals"
  Effect.ExchangeValues {} -> "ExchangeValues"
  Effect.ExchangeZones {} -> "ExchangeZones"
  Effect.ExchangeCardZones {} -> "ExchangeCardZones"
  Effect.SetLifeTotal {} -> "SetLifeTotal"
  Effect.LoseGame {} -> "LoseGame"
  Effect.WinGame {} -> "WinGame"
  Effect.DrawGame {} -> "DrawGame"
  Effect.RedistributeLifeTotals {} -> "RedistributeLifeTotals"
  Effect.IncreaseSpeed {} -> "IncreaseSpeed"
  Effect.DecreaseSpeed {} -> "DecreaseSpeed"
  Effect.Create {} -> "Create"
  Effect.Conjure {} -> "Conjure"
  Effect.CreateCopy {} -> "CreateCopy"
  Effect.CopyStackObject {} -> "CopyStackObject"
  Effect.BecomeCopy {} -> "BecomeCopy"
  Effect.Replace {} -> "Replace"
  Effect.SkipPhase {} -> "SkipPhase"
  Effect.PreventNextDamage {} -> "PreventNextDamage"
  Effect.PreventAllDamage {} -> "PreventAllDamage"
  Effect.PreventNextDamageInstance {} -> "PreventNextDamageInstance"
  Effect.RedirectDamage {} -> "RedirectDamage"
  Effect.PutCounters {} -> "PutCounters"
  Effect.Divide {} -> "Divide"
  Effect.MoveCounters {} -> "MoveCounters"
  Effect.PutCountersFrom {} -> "PutCountersFrom"
  Effect.RemoveCounters {} -> "RemoveCounters"
  Effect.RemoveCountersAmong {} -> "RemoveCountersAmong"
  Effect.GainPlayerCounters {} -> "GainPlayerCounters"
  Effect.RemovePlayerCounters {} -> "RemovePlayerCounters"
  Effect.PayAnyEnergy {} -> "PayAnyEnergy"
  Effect.ChooseNumber {} -> "ChooseNumber"
  Effect.BindAmount {} -> "BindAmount"
  Effect.Tap {} -> "Tap"
  Effect.Untap {} -> "Untap"
  Effect.Unattach {} -> "Unattach"
  Effect.Detain {} -> "Detain"
  Effect.Earthbend {} -> "Earthbend"
  Effect.Airbend {} -> "Airbend"
  Effect.Goad {} -> "Goad"
  Effect.Pair {} -> "Pair"
  Effect.DoesNotUntapNext {} -> "DoesNotUntapNext"
  Effect.Transform {} -> "Transform"
  Effect.Convert {} -> "Convert"
  Effect.Flip {} -> "Flip"
  Effect.Meld {} -> "Meld"
  Effect.PhaseOut {} -> "PhaseOut"
  Effect.AddPhases {} -> "AddPhases"
  Effect.EndTurn {} -> "EndTurn"
  Effect.EndCombatPhase {} -> "EndCombatPhase"
  Effect.GainControl {} -> "GainControl"
  Effect.ExchangeControl {} -> "ExchangeControl"
  Effect.ArmDelayedTrigger {} -> "ArmDelayedTrigger"
  Effect.AffectPlayers {} -> "AffectPlayers"
  Effect.RequireBlock {} -> "RequireBlock"
  Effect.RequireAttack {} -> "RequireAttack"
  Effect.Prohibit {} -> "Prohibit"
  Effect.ForbidAttack {} -> "ForbidAttack"
  Effect.ForbidBeingBlocked {} -> "ForbidBeingBlocked"
  Effect.CreateEmblem {} -> "CreateEmblem"
  Effect.BecomeMonarch {} -> "BecomeMonarch"
  Effect.TakeTheInitiative {} -> "TakeTheInitiative"
  Effect.Designate {} -> "Designate"
  Effect.SetClassLevel {} -> "SetClassLevel"
  Effect.Unsuspect {} -> "Unsuspect"
  Effect.SetHalfLocked {} -> "SetHalfLocked"
  Effect.CounterAndMark {} -> "CounterAndMark"
  Effect.BecomeProtector {} -> "BecomeProtector"
  Effect.Mentor {} -> "Mentor"
  Effect.Exploit {} -> "Exploit"
  Effect.GiveGift {} -> "GiveGift"
  Effect.Firebend {} -> "Firebend"
  Effect.ItBecomes {} -> "ItBecomes"
  Effect.ExileHaunting {} -> "ExileHaunting"
  Effect.Attach {} -> "Attach"
  Effect.AttachAsThoughCreature {} -> "AttachAsThoughCreature"
  Effect.AttachTarget {} -> "AttachTarget"
  Effect.AttachTargetToEach {} -> "AttachTargetToEach"
  Effect.AttachBound {} -> "AttachBound"
  Effect.AttachAll {} -> "AttachAll"
  Effect.PlaySubgame {} -> "PlaySubgame"
  Effect.ChoosePlayer {} -> "ChoosePlayer"
  Effect.ChoosePlayerAtRandom {} -> "ChoosePlayerAtRandom"
  Effect.ChoosePermanents {} -> "ChoosePermanents"
  Effect.ChooseSector {} -> "ChooseSector"
  Effect.RollDie {} -> "RollDie"
  Effect.FlipCoin {} -> "FlipCoin"
  Effect.TakeExtraTurn {} -> "TakeExtraTurn"
  Effect.ShuffleIntoLibrary {} -> "ShuffleIntoLibrary"
  Effect.Ante {} -> "Ante"
  Effect.PutSticker {} -> "PutSticker"
  Effect.SetOwner {} -> "SetOwner"
  Effect.ExchangeOwnership {} -> "ExchangeOwnership"
  Effect.Shuffle {} -> "Shuffle"
  Effect.OfferCast {} -> "OfferCast"
  Effect.OfferNamedCopy {} -> "OfferNamedCopy"
  Effect.OfferNotedCopy {} -> "OfferNotedCopy"
  Effect.GrantPlayFromExile {} -> "GrantPlayFromExile"
  Effect.GrantLookAtExiled {} -> "GrantLookAtExiled"
  Effect.MakePlotted {} -> "MakePlotted"
  Effect.MakeForetold {} -> "MakeForetold"
  Effect.MakeWarped {} -> "MakeWarped"
  Effect.ForEach {} -> "ForEach"
  Effect.ForEachNumber {} -> "ForEachNumber"
  Effect.Repeat {} -> "Repeat"
  Effect.RepeatIf {} -> "RepeatIf"
  Effect.Heal {} -> "Heal"
  Effect.ChooseNewTargets {} -> "ChooseNewTargets"
  Effect.ChangeTargets {} -> "ChangeTargets"
