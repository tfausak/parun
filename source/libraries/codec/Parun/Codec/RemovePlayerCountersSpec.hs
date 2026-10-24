module Parun.Codec.RemovePlayerCountersSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.RemovePlayerCounters as RemovePlayerCounters
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RemovePlayerCounters as RemovePlayerCounters
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RemovePlayerCounters" $ do
  Spec.it s "no tally, the three keys alone" $
    Common.assertCodec
      s
      RemovePlayerCounters.codec
      ( RemovePlayerCounters.MkRemovePlayerCounters
          { RemovePlayerCounters.player = PlayerRef.Relative PlayerRelation.You,
            RemovePlayerCounters.kind = PlayerCounterKind.Rad,
            RemovePlayerCounters.quantity = Quantity.Literal 2,
            RemovePlayerCounters.tally = Nothing
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"kind\":{\"type\":\"Rad\"},\"quantity\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "a tally, Leeches' \"that much\"" $
    Common.assertCodec
      s
      RemovePlayerCounters.codec
      ( RemovePlayerCounters.MkRemovePlayerCounters
          { RemovePlayerCounters.player = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            RemovePlayerCounters.kind = PlayerCounterKind.Poison,
            RemovePlayerCounters.quantity = Quantity.Literal 3,
            RemovePlayerCounters.tally = Just (SlotName.MkSlotName (Text.pack "lost"))
          }
      )
      " {\"player\":{\"type\":\"InSlot\",\"value\":\"target\"},\"kind\":{\"type\":\"Poison\"},\"quantity\":{\"type\":\"Literal\",\"value\":3},\"tally\":\"lost\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s RemovePlayerCounters.codec
