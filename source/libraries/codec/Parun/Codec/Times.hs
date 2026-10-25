{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Times where

import qualified Data.Typeable as Typeable
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Times as Times

-- | A bare object keyed by the record's field names, Parun.Codec.Divided's shape.
--
-- The quantity codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.Times gives: the record is parametric in the quantity so that
-- neither module has to name the other.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (Times.Times quantity)
codec quantityCodec = Fields.object $ do
  factor <- Fields.required "factor" Common.natural Times.factor
  quantity <- Fields.required "quantity" quantityCodec Times.quantity
  pure Times.MkTimes {Times.factor = factor, Times.quantity = quantity}
