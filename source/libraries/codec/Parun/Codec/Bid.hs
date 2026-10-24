{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Bid where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Bid as Bid

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's Bid arm.
codec :: Codec.Codec Bid.Bid
codec = Fields.object $ do
  opening <- Fields.required "opening" Quantity.codec Bid.opening
  highBid <- Fields.required "highBid" SlotName.codec Bid.highBid
  highBidder <- Fields.required "highBidder" SlotName.codec Bid.highBidder
  pure
    Bid.MkBid
      { Bid.opening = opening,
        Bid.highBid = highBid,
        Bid.highBidder = highBidder
      }
