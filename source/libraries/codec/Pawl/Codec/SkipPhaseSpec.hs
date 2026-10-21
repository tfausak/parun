module Pawl.Codec.SkipPhaseSpec where

import qualified Pawl.Codec.SkipPhase as SkipPhase
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.PhaseSelector as PhaseSelector
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.SkipPhase as SkipPhase
import qualified Pawl.Types.Uses as Uses

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.SkipPhase" $ do
  -- CR 614.10a: the next occurrence, so both lifetime keys are omitted.
  Spec.it s "MkSkipPhase, the next occurrence" $
    Common.assertCodec
      s
      SkipPhase.codec
      ( SkipPhase.MkSkipPhase
          { SkipPhase.player = PlayerRef.Relative PlayerRelation.You,
            SkipPhase.selector = PhaseSelector.CombatPhase,
            SkipPhase.uses = Uses.Once,
            SkipPhase.duration = Duration.Indefinite
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"selector\":{\"type\":\"CombatPhase\"}} "
  -- CR 614.3: every occurrence inside a window, so both keys are written.
  Spec.it s "MkSkipPhase, every occurrence in a window" $
    Common.assertCodec
      s
      SkipPhase.codec
      ( SkipPhase.MkSkipPhase
          { SkipPhase.player = PlayerRef.Relative PlayerRelation.You,
            SkipPhase.selector = PhaseSelector.CombatPhase,
            SkipPhase.uses = Uses.Unlimited,
            SkipPhase.duration = Duration.DuringYourNextTurn
          }
      )
      " {\"duration\":{\"type\":\"DuringYourNextTurn\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"selector\":{\"type\":\"CombatPhase\"},\"uses\":{\"type\":\"Unlimited\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SkipPhase.codec
