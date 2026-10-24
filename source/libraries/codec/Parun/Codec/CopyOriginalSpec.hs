module Parun.Codec.CopyOriginalSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CopyOriginal as CopyOriginal
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CopyOriginal as CopyOriginal
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CopyOriginal" $ do
  Spec.it s "OfObject" $
    Common.assertCodec
      s
      CopyOriginal.codec
      (CopyOriginal.OfObject (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "became"))))
      " {\"type\":\"OfObject\",\"value\":{\"type\":\"InSlot\",\"value\":\"became\"}} "
  Spec.it s "Named" $
    Common.assertCodec
      s
      CopyOriginal.codec
      (CopyOriginal.Named (CardName.MkCardName (Text.pack "Lightning Bolt")))
      " {\"type\":\"Named\",\"value\":\"Lightning Bolt\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CopyOriginal.codec
