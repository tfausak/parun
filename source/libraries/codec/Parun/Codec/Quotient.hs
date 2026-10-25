{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Quotient where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Rounding as Rounding
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Quotient as Quotient

-- | A bare object keyed by the record's field names (#1464).
--
-- The quantity codec is a PARAMETER rather than an import, for the reason
-- Parun.Types.Quotient gives: the record is parametric in the quantity so that
-- neither module has to name the other. Parun.Codec.Quantity passes its own
-- 'Parun.Codec.Quantity.codec' in, which is the knot Parun.Codec.Count already
-- ties from the same place.
codec :: (Typeable.Typeable quantity) => Codec.Codec quantity -> Codec.Codec (Quotient.Quotient quantity)
codec quantityCodec = Fields.object $ do
  rounding <- Fields.required "rounding" Rounding.codec Quotient.rounding
  quantity <- Fields.required "quantity" quantityCodec Quotient.quantity
  divisor <- Fields.required "divisor" quantityCodec Quotient.divisor
  pure Quotient.MkQuotient {Quotient.rounding = rounding, Quotient.quantity = quantity, Quotient.divisor = divisor}
