{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Divided where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Rounding as Rounding
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Divided as Divided

-- | A bare object keyed by the record's field names (#1464).
--
-- The quantity codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.Divided gives: the record is parametric in the quantity so that
-- neither module has to name the other. Parun.Codec.Quantity passes its own
-- 'Parun.Codec.Quantity.codec' in, which is the knot Parun.Codec.Count already
-- ties from the same place.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (Divided.Divided quantity)
codec quantityCodec = Fields.object $ do
  rounding <- Fields.required "rounding" Rounding.codec Divided.rounding
  quantity <- Fields.required "quantity" quantityCodec Divided.quantity
  divisor <- Fields.required "divisor" quantityCodec Divided.divisor
  pure Divided.MkDivided {Divided.rounding = rounding, Divided.quantity = quantity, Divided.divisor = divisor}
