module Parun.Codec.ForEachNumberSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.ForEachNumber as ForEachNumber
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ForEachNumber as ForEachNumber
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Text.Text' for Parun.Codec.ForEachSpec's reason.
codec :: Codec.Codec (ForEachNumber.ForEachNumber Text.Text)
codec = ForEachNumber.codec Common.text

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ForEachNumber" $ do
  -- Ornate Imitations' shape: up to the spell's X.
  Spec.it s "MkForEachNumber" $
    Common.assertCodec
      s
      codec
      ( ForEachNumber.MkForEachNumber
          { ForEachNumber.upTo = Quantity.InSlot (SlotName.MkSlotName (Text.pack "X")),
            ForEachNumber.slot = SlotName.MkSlotName (Text.pack "number"),
            ForEachNumber.body = Seq.fromList [Text.pack "first", Text.pack "second"]
          }
      )
      " {\"upTo\":{\"type\":\"InSlot\",\"value\":\"X\"},\"slot\":\"number\",\"body\":[\"first\",\"second\"]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
