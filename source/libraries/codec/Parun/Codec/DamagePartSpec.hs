module Parun.Codec.DamagePartSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.DamagePart as DamagePart
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DamagePart" $ do
  -- One recipient description and the amount each of its recipients gets.
  Spec.it s "MkDamagePart" $
    Common.assertCodec
      s
      DamagePart.codec
      ( DamagePart.MkDamagePart
          { DamagePart.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            DamagePart.quantity = Quantity.Literal 4
          }
      )
      " {\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"},\"quantity\":{\"type\":\"Literal\",\"value\":4}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DamagePart.codec
