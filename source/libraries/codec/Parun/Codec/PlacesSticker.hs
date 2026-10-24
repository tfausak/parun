{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlacesSticker where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.StickerKind as StickerKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.PlacesSticker as PlacesSticker

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec PlacesSticker.PlacesSticker
codec = Fields.object $ do
  placer <- Fields.required "placer" PlayerRelation.codec PlacesSticker.placer
  kinds <- Fields.required "kinds" (Common.set StickerKind.codec) PlacesSticker.kinds
  object <- Fields.defaulted "object" (Filter.Type.And []) (Filter.codec Keyword.codec) PlacesSticker.object
  pure
    PlacesSticker.MkPlacesSticker
      { PlacesSticker.placer = placer,
        PlacesSticker.kinds = kinds,
        PlacesSticker.object = object
      }
