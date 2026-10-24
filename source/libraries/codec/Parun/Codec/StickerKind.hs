module Parun.Codec.StickerKind where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.StickerKind as StickerKind

codec :: Codec.Codec StickerKind.StickerKind
codec = Arm.enum
