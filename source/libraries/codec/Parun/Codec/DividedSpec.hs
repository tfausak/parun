module Parun.Codec.DividedSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Divided as Divided
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Divided as Divided
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Rounding as Rounding
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (Divided.Divided Quantity.Quantity)
codec = Divided.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Divided" $ do
  -- CR 107.1a: Malignus' half, rounded up. Both operands are whole Quantities, so the recursion has to survive the trip on each.
  Spec.it s "MkDivided" $
    Common.assertCodec
      s
      codec
      ( Divided.MkDivided
          { Divided.rounding = Rounding.Up,
            Divided.quantity = Quantity.Measure Measure.Power,
            Divided.divisor = Quantity.Literal 2
          }
      )
      " {\"rounding\":{\"type\":\"Up\"},\"quantity\":{\"type\":\"Measure\",\"value\":{\"type\":\"Power\"}},\"divisor\":{\"type\":\"Literal\",\"value\":2}} "
  -- Fireball's divisor, a count of its targets.
  Spec.it s "MkDivided by a count" $
    Common.assertCodec
      s
      codec
      ( Divided.MkDivided
          { Divided.rounding = Rounding.Down,
            Divided.quantity = Quantity.InSlot (SlotName.MkSlotName (Text.pack "X")),
            Divided.divisor = Quantity.BoundCount (SlotName.MkSlotName (Text.pack "targets"))
          }
      )
      " {\"rounding\":{\"type\":\"Down\"},\"quantity\":{\"type\":\"InSlot\",\"value\":\"X\"},\"divisor\":{\"type\":\"BoundCount\",\"value\":\"targets\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
