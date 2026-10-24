module Parun.Codec.StickerKindSpec where

import qualified Parun.Codec.StickerKind as StickerKind
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.StickerKind as StickerKind

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.StickerKind" $ do
  Spec.it s "Art" $ Common.assertCodec s StickerKind.codec StickerKind.Art " {\"type\":\"Art\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s StickerKind.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s StickerKind.codec
