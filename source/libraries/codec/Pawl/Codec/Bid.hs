{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Bid where

import qualified Pawl.Codec.Quantity as Quantity
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Bid as Bid

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Pawl.Codec.Effect's Bid arm.
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
