module Parun.Codec.DesignateSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Designate as Designate
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Designate as Designate
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Designate" $ do
  -- CR 701.60 / CR 702.112: give the slot's object this designation.
  Spec.it s "MkDesignate, the two required keys" $
    Common.assertCodec
      s
      Designate.codec
      ( Designate.MkDesignate
          { Designate.designation = Designation.Suspected,
            Designate.slot = SlotName.MkSlotName (Text.pack "self"),
            Designate.value = Nothing
          }
      )
      " {\"designation\":{\"type\":\"Suspected\"},\"slot\":\"self\"} "
  -- CR 701.37c's X, which only a "Monstrosity X" writes.
  Spec.it s "MkDesignate carries the value the mark was set with" $
    Common.assertCodec
      s
      Designate.codec
      ( Designate.MkDesignate
          { Designate.designation = Designation.Monstrous,
            Designate.slot = SlotName.MkSlotName (Text.pack "self"),
            Designate.value = Just (Quantity.InSlot (SlotName.MkSlotName (Text.pack "X")))
          }
      )
      " {\"designation\":{\"type\":\"Monstrous\"},\"slot\":\"self\",\"value\":{\"type\":\"InSlot\",\"value\":\"X\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Designate.codec
