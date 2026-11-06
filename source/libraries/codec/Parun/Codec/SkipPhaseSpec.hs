module Parun.Codec.SkipPhaseSpec where

import qualified Parun.Codec.SkipPhase as SkipPhase
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SkipPhase as SkipPhase.Type
import qualified Parun.Types.SkipWindow as SkipWindow
import qualified Parun.Types.Uses as Uses

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SkipPhase" $ do
  -- CR 614.10a: the next occurrence, so both lifetime keys and the count are omitted.
  Spec.it s "MkSkipPhase, the next occurrence" $
    Common.assertCodec
      s
      SkipPhase.codec
      ( SkipPhase.Type.MkSkipPhase
          { SkipPhase.Type.player = PlayerRef.Relative PlayerRelation.You,
            SkipPhase.Type.selector = SkipWindow.PartOfTurn PhaseSelector.CombatPhase,
            SkipPhase.Type.uses = Uses.Once,
            SkipPhase.Type.duration = Duration.Indefinite,
            SkipPhase.Type.count = SkipPhase.Type.defaultCount
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":\"You\"},\"selector\":{\"type\":\"CombatPhase\"}} "
  -- CR 614.3: every occurrence inside a window, so both keys are written.
  Spec.it s "MkSkipPhase, every occurrence in a window" $
    Common.assertCodec
      s
      SkipPhase.codec
      ( SkipPhase.Type.MkSkipPhase
          { SkipPhase.Type.player = PlayerRef.Relative PlayerRelation.You,
            SkipPhase.Type.selector = SkipWindow.PartOfTurn PhaseSelector.CombatPhase,
            SkipPhase.Type.uses = Uses.Unlimited,
            SkipPhase.Type.duration = Duration.DuringYourNextTurn,
            SkipPhase.Type.count = SkipPhase.Type.defaultCount
          }
      )
      " {\"duration\":{\"type\":\"DuringYourNextTurn\"},\"player\":{\"type\":\"Relative\",\"value\":\"You\"},\"selector\":{\"type\":\"CombatPhase\"},\"uses\":\"Unlimited\"} "
  -- CR 614.10a: Eater of Days' "your next two turns", the count written.
  Spec.it s "MkSkipPhase, the next two turns" $
    Common.assertCodec
      s
      SkipPhase.codec
      ( SkipPhase.Type.MkSkipPhase
          { SkipPhase.Type.player = PlayerRef.Relative PlayerRelation.You,
            SkipPhase.Type.selector = SkipWindow.WholeTurn,
            SkipPhase.Type.uses = Uses.Once,
            SkipPhase.Type.duration = Duration.Indefinite,
            SkipPhase.Type.count = Quantity.Literal 2
          }
      )
      " {\"count\":{\"type\":\"Literal\",\"value\":2},\"player\":{\"type\":\"Relative\",\"value\":\"You\"},\"selector\":{\"type\":\"Turn\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SkipPhase.codec
