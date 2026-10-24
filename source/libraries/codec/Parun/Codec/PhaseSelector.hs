module Parun.Codec.PhaseSelector where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PhaseSelector as PhaseSelector

codec :: Codec.Codec PhaseSelector.PhaseSelector
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Step" Phase.codec PhaseSelector.Step (\x -> case x of PhaseSelector.Step y -> Just y; _ -> Nothing),
      Arm.nullary "BeginningPhase" PhaseSelector.BeginningPhase,
      Arm.nullary "CombatPhase" PhaseSelector.CombatPhase,
      Arm.nullary "EndingPhase" PhaseSelector.EndingPhase
    ]

tagOf :: PhaseSelector.PhaseSelector -> String
tagOf x = case x of
  PhaseSelector.Step {} -> "Step"
  PhaseSelector.BeginningPhase {} -> "BeginningPhase"
  PhaseSelector.CombatPhase {} -> "CombatPhase"
  PhaseSelector.EndingPhase {} -> "EndingPhase"
