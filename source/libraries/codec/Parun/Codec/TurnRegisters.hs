{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TurnRegisters where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.CastFromZone as CastFromZone
import qualified Parun.Codec.Combat as Combat
import qualified Parun.Codec.EndTurnSignal as EndTurnSignal
import qualified Parun.Codec.EventGroup as EventGroup
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.LastKnown as LastKnown
import qualified Parun.Codec.LoggedEvent as LoggedEvent
import qualified Parun.Codec.ModifiedRoll as ModifiedRoll
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PastActivation as PastActivation
import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.Codec.TurnResume as TurnResume
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EndTurnSignal as EndTurnSignal.Type
import qualified Parun.Types.TurnRegisters as TurnRegisters
import qualified Parun.Types.TurnResume as TurnResume.Type

-- | Each field as Parun.Codec.GameState writes the field of the same name.
codec :: Codec.Codec TurnRegisters.TurnRegisters
codec = Fields.object $ do
  activePlayer <- Fields.required "activePlayer" PlayerId.codec TurnRegisters.activePlayer
  phase <- Fields.required "phase" Phase.codec TurnRegisters.phase
  remaining <- Fields.required "remaining" (Common.seq Phase.codec) TurnRegisters.remaining
  stack <- Fields.defaulted "stack" [] (Common.list ObjectId.codec) TurnRegisters.stack
  stackedIn <- Fields.defaulted "stackedIn" Map.empty (Common.naturalMap ObjectId.codec EventGroup.codec) TurnRegisters.stackedIn
  priority <- Fields.defaulted "priority" Nothing (Common.maybe PlayerId.codec) TurnRegisters.priority
  passed <- Fields.defaulted "passed" Set.empty (Common.set PlayerId.codec) TurnRegisters.passed
  combat <- Fields.required "combat" Combat.codec TurnRegisters.combat
  events <- Fields.defaulted "events" Seq.empty (Common.seq LoggedEvent.codec) TurnRegisters.events
  scannedThrough <- Fields.defaulted "scannedThrough" 0 Common.natural TurnRegisters.scannedThrough
  damageScannedThrough <- Fields.defaulted "damageScannedThrough" 0 Common.natural TurnRegisters.damageScannedThrough
  turnNumber <- Fields.required "turnNumber" Common.natural TurnRegisters.turnNumber
  turnAnchor <- Fields.defaulted "turnAnchor" Nothing (Common.maybe PlayerId.codec) TurnRegisters.turnAnchor
  extraTurnUnderWay <- Fields.defaulted "extraTurnUnderWay" Nothing (Common.maybe Timestamp.codec) TurnRegisters.extraTurnUnderWay
  permanentsAsTurnBegan <- Fields.defaulted "permanentsAsTurnBegan" Nothing (Common.maybe (Common.naturalMap ObjectId.codec LastKnown.codec)) TurnRegisters.permanentsAsTurnBegan
  endTurnSignal <- Fields.defaulted "endTurnSignal" EndTurnSignal.Type.Running EndTurnSignal.codec TurnRegisters.endTurnSignal
  drawsThisTurn <- Fields.defaulted "drawsThisTurn" Map.empty (Common.naturalMap PlayerId.codec (Common.seq ObjectId.codec)) TurnRegisters.drawsThisTurn
  couldAttackThisTurn <- Fields.defaulted "couldAttackThisTurn" Set.empty (Common.set ObjectId.codec) TurnRegisters.couldAttackThisTurn
  activatedThisTurn <- Fields.defaulted "activatedThisTurn" Map.empty (Common.naturalMap ObjectId.codec (Common.repeats (ActivatedAbility.codec Card.codec (GrantedAbility.codec Card.codec)))) TurnRegisters.activatedThisTurn
  activationsThisTurn <- Fields.defaulted "activationsThisTurn" Seq.empty (Common.seq PastActivation.codec) TurnRegisters.activationsThisTurn
  castPermissionsUsedThisTurn <- Fields.defaulted "castPermissionsUsedThisTurn" Map.empty (Common.naturalMap ObjectId.codec (Common.set CastFromZone.codec)) TurnRegisters.castPermissionsUsedThisTurn
  rollModifiersUsedThisTurn <- Fields.defaulted "rollModifiersUsedThisTurn" Map.empty (Common.naturalMap ObjectId.codec (Common.set ModifiedRoll.codec)) TurnRegisters.rollModifiersUsedThisTurn
  turnResume <- Fields.defaulted "turnResume" TurnResume.Type.AtStepStart TurnResume.codec TurnRegisters.turnResume
  pure
    TurnRegisters.MkTurnRegisters
      { TurnRegisters.activePlayer = activePlayer,
        TurnRegisters.phase = phase,
        TurnRegisters.remaining = remaining,
        TurnRegisters.stack = stack,
        TurnRegisters.stackedIn = stackedIn,
        TurnRegisters.priority = priority,
        TurnRegisters.passed = passed,
        TurnRegisters.combat = combat,
        TurnRegisters.events = events,
        TurnRegisters.scannedThrough = scannedThrough,
        TurnRegisters.damageScannedThrough = damageScannedThrough,
        TurnRegisters.turnNumber = turnNumber,
        TurnRegisters.turnAnchor = turnAnchor,
        TurnRegisters.extraTurnUnderWay = extraTurnUnderWay,
        TurnRegisters.permanentsAsTurnBegan = permanentsAsTurnBegan,
        TurnRegisters.endTurnSignal = endTurnSignal,
        TurnRegisters.drawsThisTurn = drawsThisTurn,
        TurnRegisters.couldAttackThisTurn = couldAttackThisTurn,
        TurnRegisters.activatedThisTurn = activatedThisTurn,
        TurnRegisters.activationsThisTurn = activationsThisTurn,
        TurnRegisters.castPermissionsUsedThisTurn = castPermissionsUsedThisTurn,
        TurnRegisters.rollModifiersUsedThisTurn = rollModifiersUsedThisTurn,
        TurnRegisters.turnResume = turnResume
      }
