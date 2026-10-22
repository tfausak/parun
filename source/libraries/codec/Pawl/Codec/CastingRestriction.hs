module Pawl.Codec.CastingRestriction where

import qualified Pawl.Codec.DuringPhase as DuringPhase
import qualified Pawl.Codec.Phase as Phase
import qualified Pawl.Codec.TurnScope as TurnScope
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.CastingRestriction as CastingRestriction

codec :: Codec.Codec CastingRestriction.CastingRestriction
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "DuringPhase" DuringPhase.codec CastingRestriction.DuringPhase (\x -> case x of CastingRestriction.DuringPhase y -> Just y; _ -> Nothing),
      Arm.nullary "AttackedThisStep" CastingRestriction.AttackedThisStep,
      Arm.nullary "AfterBlockersDeclared" CastingRestriction.AfterBlockersDeclared,
      Arm.payload "BeforeStep" Phase.codec CastingRestriction.BeforeStep (\x -> case x of CastingRestriction.BeforeStep y -> Just y; _ -> Nothing),
      Arm.payload "DuringTurn" TurnScope.codec CastingRestriction.DuringTurn (\x -> case x of CastingRestriction.DuringTurn y -> Just y; _ -> Nothing)
    ]

tagOf :: CastingRestriction.CastingRestriction -> String
tagOf x = case x of
  CastingRestriction.DuringPhase {} -> "DuringPhase"
  CastingRestriction.AttackedThisStep {} -> "AttackedThisStep"
  CastingRestriction.AfterBlockersDeclared {} -> "AfterBlockersDeclared"
  CastingRestriction.BeforeStep {} -> "BeforeStep"
  CastingRestriction.DuringTurn {} -> "DuringTurn"
