module Parun.Codec.AtMostSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Parun.Codec.AtMost as AtMost
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AtMost as AtMost
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (AtMost.AtMost Quantity.Quantity)
codec = AtMost.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AtMost" $ do
  Spec.it s "MkAtMost" $
    Common.assertCodec
      s
      codec
      AtMost.MkAtMost {AtMost.quantity = slot "dealt", AtMost.limits = slot "life" NonEmpty.:| [slot "toughness"]}
      " {\"quantity\":{\"type\":\"InSlot\",\"value\":\"dealt\"},\"limits\":[{\"type\":\"InSlot\",\"value\":\"life\"},{\"type\":\"InSlot\",\"value\":\"toughness\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
  where
    slot = Quantity.InSlot . SlotName.MkSlotName . Text.pack
