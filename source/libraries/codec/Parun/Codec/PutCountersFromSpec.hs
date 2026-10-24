module Parun.Codec.PutCountersFromSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.PutCountersFrom as PutCountersFrom
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PutCountersFrom as PutCountersFrom
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PutCountersFrom" $ do
  -- No count: CR 122.8's per-kind tally is what crosses. `kind` defaults to the
  -- whole tally -- rule 122.8's first sentence -- so it writes no key here.
  Spec.it s "MkPutCountersFrom, no kind named" $
    Common.assertCodec
      s
      PutCountersFrom.codec
      ( PutCountersFrom.MkPutCountersFrom
          { PutCountersFrom.from = SlotName.MkSlotName (Text.pack "self"),
            PutCountersFrom.kind = Nothing,
            PutCountersFrom.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))
          }
      )
      " {\"from\":\"self\",\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  -- CR 122.8's second sentence, the kind written down.
  Spec.it s "MkPutCountersFrom, a kind named" $
    Common.assertCodec
      s
      PutCountersFrom.codec
      ( PutCountersFrom.MkPutCountersFrom
          { PutCountersFrom.from = SlotName.MkSlotName (Text.pack "self"),
            PutCountersFrom.kind = Just CounterKind.PlusOnePlusOne,
            PutCountersFrom.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target"))
          }
      )
      " {\"from\":\"self\",\"kind\":{\"type\":\"PlusOnePlusOne\"},\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PutCountersFrom.codec
