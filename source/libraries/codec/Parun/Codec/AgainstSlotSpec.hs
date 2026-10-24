module Parun.Codec.AgainstSlotSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.AgainstSlot as AgainstSlot
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AgainstSlot as AgainstSlot
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (AgainstSlot.AgainstSlot Quantity.Quantity)
codec = AgainstSlot.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AgainstSlot" $ do
  -- Which object to aim at, then what to read off it.
  Spec.it s "MkAgainstSlot" $
    Common.assertCodec
      s
      codec
      ( AgainstSlot.MkAgainstSlot
          { AgainstSlot.slot = SlotName.MkSlotName (Text.pack "target"),
            AgainstSlot.quantity = Quantity.Measure Measure.Toughness
          }
      )
      " {\"slot\":\"target\",\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Toughness\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
