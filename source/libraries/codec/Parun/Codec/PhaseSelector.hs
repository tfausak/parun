module Parun.Codec.PhaseSelector where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PhaseSelector as PhaseSelector

codec :: Codec.Codec PhaseSelector.PhaseSelector
codec = Arm.tagged tagOf (arms id Just)

-- | The selector's arms as arms of a tagged type that wraps it, under the
-- selector's own tags, so Parun.Codec.SkipWindow spells a step or phase the way
-- every other selector does.
arms :: (Eq a) => (PhaseSelector.PhaseSelector -> a) -> (a -> Maybe PhaseSelector.PhaseSelector) -> [Arm.Arm a]
arms inject project =
  [ Arm.payload "Step" Phase.codec (inject . PhaseSelector.Step) (\x -> case project x of Just (PhaseSelector.Step y) -> Just y; _ -> Nothing),
    Arm.nullary "BeginningPhase" (inject PhaseSelector.BeginningPhase),
    Arm.nullary "CombatPhase" (inject PhaseSelector.CombatPhase),
    Arm.nullary "EndingPhase" (inject PhaseSelector.EndingPhase)
  ]

tagOf :: PhaseSelector.PhaseSelector -> String
tagOf x = case x of
  PhaseSelector.Step {} -> "Step"
  PhaseSelector.BeginningPhase {} -> "BeginningPhase"
  PhaseSelector.CombatPhase {} -> "CombatPhase"
  PhaseSelector.EndingPhase {} -> "EndingPhase"
