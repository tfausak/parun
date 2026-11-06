module Parun.Codec.TurnRegistersSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.CombatSpec as CombatSpec
import qualified Parun.Codec.TurnRegisters as TurnRegisters
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.EndTurnSignal as EndTurnSignal
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.TurnRegisters as TurnRegisters
import qualified Parun.Types.TurnResume as TurnResume

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnRegisters" $ do
  -- CR 807.5: the second marker's turn parked in its upkeep with a spell on
  -- its own stack and its window open, every defaulted field at its default.
  Spec.it s "a turn parked with a spell on its stack" $
    Common.assertCodec
      s
      TurnRegisters.codec
      TurnRegisters.MkTurnRegisters
        { TurnRegisters.activePlayer = PlayerId.MkPlayerId 4,
          TurnRegisters.phase = Phase.Beginning BeginningStep.Upkeep,
          TurnRegisters.remaining = Seq.empty,
          TurnRegisters.stack = [ObjectId.MkObjectId 7],
          TurnRegisters.stackedIn = Map.empty,
          TurnRegisters.priority = Just (PlayerId.MkPlayerId 5),
          TurnRegisters.passed = Set.empty,
          TurnRegisters.combat = CombatSpec.empty,
          TurnRegisters.events = Seq.empty,
          TurnRegisters.scannedThrough = 0,
          TurnRegisters.damageScannedThrough = 0,
          TurnRegisters.turnNumber = 2,
          TurnRegisters.turnAnchor = Nothing,
          TurnRegisters.extraTurnUnderWay = Nothing,
          TurnRegisters.permanentsAsTurnBegan = Nothing,
          TurnRegisters.endTurnSignal = EndTurnSignal.Running,
          TurnRegisters.drawsThisTurn = Map.empty,
          TurnRegisters.couldAttackThisTurn = Set.empty,
          TurnRegisters.activatedThisTurn = Map.empty,
          TurnRegisters.activationsThisTurn = Seq.empty,
          TurnRegisters.castPermissionsUsedThisTurn = Map.empty,
          TurnRegisters.rollModifiersUsedThisTurn = Map.empty,
          TurnRegisters.turnResume = TurnResume.InWindow
        }
      (" {\"activePlayer\":4,\"phase\":{\"type\":\"Beginning\",\"value\":\"Upkeep\"},\"remaining\":[],\"stack\":[7],\"priority\":5,\"combat\":" <> CombatSpec.emptyJson <> ",\"turnNumber\":2,\"turnResume\":\"InWindow\"} ")
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnRegisters.codec
