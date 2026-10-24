{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PutSticker where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.StickerKind as StickerKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PutSticker as PutSticker

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec PutSticker.PutSticker
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec PutSticker.player
  ref <- Fields.required "ref" ObjectRef.codec PutSticker.ref
  kinds <- Fields.required "kinds" (Common.set StickerKind.codec) PutSticker.kinds
  ticketCap <- Fields.defaulted "ticketCap" Nothing (Common.maybe Quantity.codec) PutSticker.ticketCap
  free <- Fields.defaulted "free" False Common.boolean PutSticker.free
  bound <- Fields.defaulted "bound" Nothing (Common.maybe SlotName.codec) PutSticker.bound
  pure
    PutSticker.MkPutSticker
      { PutSticker.player = player,
        PutSticker.ref = ref,
        PutSticker.kinds = kinds,
        PutSticker.ticketCap = ticketCap,
        PutSticker.free = free,
        PutSticker.bound = bound
      }
