module Parun.Codec.SkipWindowSpec where

import qualified Parun.Codec.SkipWindow as SkipWindow
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.SkipWindow as SkipWindow.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SkipWindow" $ do
  Spec.it s "Step" $
    Common.assertCodec
      s
      SkipWindow.codec
      (SkipWindow.Type.PartOfTurn (PhaseSelector.Step (Phase.Beginning BeginningStep.DrawStep)))
      " {\"type\":\"Step\",\"value\":{\"type\":\"Beginning\",\"value\":\"DrawStep\"}} "
  Spec.it s "BeginningPhase" $
    Common.assertCodec
      s
      SkipWindow.codec
      (SkipWindow.Type.PartOfTurn PhaseSelector.BeginningPhase)
      " {\"type\":\"BeginningPhase\"} "
  Spec.it s "CombatPhase" $
    Common.assertCodec
      s
      SkipWindow.codec
      (SkipWindow.Type.PartOfTurn PhaseSelector.CombatPhase)
      " {\"type\":\"CombatPhase\"} "
  Spec.it s "EndingPhase" $
    Common.assertCodec
      s
      SkipWindow.codec
      (SkipWindow.Type.PartOfTurn PhaseSelector.EndingPhase)
      " {\"type\":\"EndingPhase\"} "
  Spec.it s "Turn" $
    Common.assertCodec
      s
      SkipWindow.codec
      SkipWindow.Type.WholeTurn
      " {\"type\":\"Turn\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s SkipWindow.codec
