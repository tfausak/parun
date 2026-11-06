module Parun.Codec.SkipWindow where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.SkipWindow as SkipWindow

-- | Flat: a step or phase keeps Parun.Codec.PhaseSelector's spelling, and the
-- whole turn is one more tag beside them.
codec :: Codec.Codec SkipWindow.SkipWindow
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Step" Phase.codec (SkipWindow.PartOfTurn . PhaseSelector.Step) (\x -> case x of SkipWindow.PartOfTurn (PhaseSelector.Step y) -> Just y; _ -> Nothing),
      Arm.nullary "BeginningPhase" (SkipWindow.PartOfTurn PhaseSelector.BeginningPhase),
      Arm.nullary "CombatPhase" (SkipWindow.PartOfTurn PhaseSelector.CombatPhase),
      Arm.nullary "EndingPhase" (SkipWindow.PartOfTurn PhaseSelector.EndingPhase),
      Arm.nullary "Turn" SkipWindow.WholeTurn
    ]

tagOf :: SkipWindow.SkipWindow -> String
tagOf x = case x of
  SkipWindow.PartOfTurn PhaseSelector.Step {} -> "Step"
  SkipWindow.PartOfTurn PhaseSelector.BeginningPhase -> "BeginningPhase"
  SkipWindow.PartOfTurn PhaseSelector.CombatPhase -> "CombatPhase"
  SkipWindow.PartOfTurn PhaseSelector.EndingPhase -> "EndingPhase"
  SkipWindow.WholeTurn -> "Turn"
