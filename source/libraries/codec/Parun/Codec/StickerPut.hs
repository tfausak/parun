{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StickerPut where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.StickerKind as StickerKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StickerPut as StickerPut

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec StickerPut.StickerPut
codec = Fields.object $ do
  placer <- Fields.required "placer" PlayerId.codec StickerPut.placer
  object <- Fields.required "object" ObjectId.codec StickerPut.object
  kind <- Fields.required "kind" StickerKind.codec StickerPut.kind
  pure
    StickerPut.MkStickerPut
      { StickerPut.placer = placer,
        StickerPut.object = object,
        StickerPut.kind = kind
      }
