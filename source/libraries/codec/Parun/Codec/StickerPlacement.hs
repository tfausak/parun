{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StickerPlacement where

import qualified Parun.Codec.StickerRef as StickerRef
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StickerPlacement as StickerPlacement

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec StickerPlacement.StickerPlacement
codec = Fields.object $ do
  sticker <- Fields.required "sticker" StickerRef.codec StickerPlacement.sticker
  timestamp <- Fields.required "timestamp" Timestamp.codec StickerPlacement.timestamp
  position <- Fields.defaulted "position" Nothing (Common.maybe Common.natural) StickerPlacement.position
  pure
    StickerPlacement.MkStickerPlacement
      { StickerPlacement.sticker = sticker,
        StickerPlacement.timestamp = timestamp,
        StickerPlacement.position = position
      }
