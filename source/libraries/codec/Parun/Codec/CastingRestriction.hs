module Parun.Codec.CastingRestriction where

import qualified Parun.Codec.CombatStep as CombatStep
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.DuringPhase as DuringPhase
import qualified Parun.Codec.ManaSymbol as ManaSymbol
import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CastingRestriction as CastingRestriction

codec :: Codec.Codec CastingRestriction.CastingRestriction
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "DuringPhase" DuringPhase.codec CastingRestriction.DuringPhase (\x -> case x of CastingRestriction.DuringPhase y -> Just y; _ -> Nothing),
      Arm.nullary "AttackedThisStep" CastingRestriction.AttackedThisStep,
      Arm.nullary "AfterBlockersDeclared" CastingRestriction.AfterBlockersDeclared,
      Arm.payload "BeforeStep" Phase.codec CastingRestriction.BeforeStep (\x -> case x of CastingRestriction.BeforeStep y -> Just y; _ -> Nothing),
      Arm.payload "DuringCombatBefore" CombatStep.codec CastingRestriction.DuringCombatBefore (\x -> case x of CastingRestriction.DuringCombatBefore y -> Just y; _ -> Nothing),
      Arm.payload "DuringTurn" TurnScope.codec CastingRestriction.DuringTurn (\x -> case x of CastingRestriction.DuringTurn y -> Just y; _ -> Nothing),
      Arm.payload "NotDuringFirstTurns" Common.natural CastingRestriction.NotDuringFirstTurns (\x -> case x of CastingRestriction.NotDuringFirstTurns y -> Just y; _ -> Nothing),
      Arm.payload "OnlyIf" Condition.codec CastingRestriction.OnlyIf (\x -> case x of CastingRestriction.OnlyIf y -> Just y; _ -> Nothing),
      Arm.payload "SpendOnlyOnX" ManaSymbol.codec CastingRestriction.SpendOnlyOnX (\x -> case x of CastingRestriction.SpendOnlyOnX y -> Just y; _ -> Nothing)
    ]

tagOf :: CastingRestriction.CastingRestriction -> String
tagOf x = case x of
  CastingRestriction.DuringPhase {} -> "DuringPhase"
  CastingRestriction.AttackedThisStep {} -> "AttackedThisStep"
  CastingRestriction.AfterBlockersDeclared {} -> "AfterBlockersDeclared"
  CastingRestriction.BeforeStep {} -> "BeforeStep"
  CastingRestriction.DuringCombatBefore {} -> "DuringCombatBefore"
  CastingRestriction.DuringTurn {} -> "DuringTurn"
  CastingRestriction.NotDuringFirstTurns {} -> "NotDuringFirstTurns"
  CastingRestriction.OnlyIf {} -> "OnlyIf"
  CastingRestriction.SpendOnlyOnX {} -> "SpendOnlyOnX"
