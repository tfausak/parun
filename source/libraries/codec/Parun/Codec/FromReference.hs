{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.FromReference where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.FromReference as FromReference

-- | A bare object keyed by the record's field names. The amount is omitted where
-- the filter names none, Parun.Codec.TargetSlot's posture for its own amount.
codec :: Codec.Codec FromReference.FromReference
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) FromReference.filter
  amount <- Fields.defaulted "amount" Nothing (Common.maybe Quantity.codec) FromReference.amount
  pure
    FromReference.MkFromReference
      { FromReference.filter = filter_,
        FromReference.amount = amount
      }
