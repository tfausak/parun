module Pawl.Codec.BidSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.Bid as Bid
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Bid as Bid
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Bid" $ do
  Spec.it s "round-trips" $
    Common.assertCodec
      s
      Bid.codec
      (Bid.MkBid (Quantity.Literal 0) (SlotName.MkSlotName (Text.pack "bid")) (SlotName.MkSlotName (Text.pack "bidder")))
      " {\"opening\":{\"type\":\"Literal\",\"value\":0},\"highBid\":\"bid\",\"highBidder\":\"bidder\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Bid.codec
