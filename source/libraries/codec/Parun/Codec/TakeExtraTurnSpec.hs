module Parun.Codec.TakeExtraTurnSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.TakeExtraTurn as TakeExtraTurn
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.TakeExtraTurn as TakeExtraTurn

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TakeExtraTurn" $ do
  -- CR 500.7. The skipped phases are a SET, written ascending, and Common.set's
  -- decoder rejects a repeat so the schema's uniqueItems stays honest.
  Spec.it s "MkTakeExtraTurn, no skipped phases" $
    Common.assertCodec
      s
      TakeExtraTurn.codec
      ( TakeExtraTurn.MkTakeExtraTurn
          { TakeExtraTurn.player = PlayerRef.Relative PlayerRelation.You,
            TakeExtraTurn.skips = Set.empty,
            TakeExtraTurn.count = Quantity.Literal 1
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"skips\":[]} "
  Spec.it s "MkTakeExtraTurn, skipped phases are written in order" $
    Common.assertCodec
      s
      TakeExtraTurn.codec
      ( TakeExtraTurn.MkTakeExtraTurn
          { TakeExtraTurn.player = PlayerRef.Relative PlayerRelation.You,
            TakeExtraTurn.skips = Set.fromList [PhaseSelector.CombatPhase, PhaseSelector.BeginningPhase],
            TakeExtraTurn.count = Quantity.Literal 1
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"skips\":[{\"type\":\"BeginningPhase\"},{\"type\":\"CombatPhase\"}]} "
  -- Ral Zarek's -7: the count is a slot read, and only a count other than one
  -- is written.
  Spec.it s "MkTakeExtraTurn, a count bound earlier" $
    Common.assertCodec
      s
      TakeExtraTurn.codec
      ( TakeExtraTurn.MkTakeExtraTurn
          { TakeExtraTurn.player = PlayerRef.Relative PlayerRelation.You,
            TakeExtraTurn.skips = Set.empty,
            TakeExtraTurn.count = Quantity.InSlot (SlotName.MkSlotName (Text.pack "heads"))
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"skips\":[],\"count\":{\"type\":\"InSlot\",\"value\":\"heads\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TakeExtraTurn.codec
