{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Compares where

import qualified Parun.Codec.Comparison as Comparison
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Compares as Compares

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Condition's Compares arm.
--
-- Naming the sides is the point: both are a Quantity, so a positional payload
-- would let a card file that swapped them decode into the wrong comparison.
codec :: Codec.Codec Compares.Compares
codec = Fields.object $ do
  measured <- Fields.required "measured" Quantity.codec Compares.measured
  comparison <- Fields.required "comparison" Comparison.codec Compares.comparison
  threshold <- Fields.required "threshold" Quantity.codec Compares.threshold
  pure
    Compares.MkCompares
      { Compares.measured = measured,
        Compares.comparison = comparison,
        Compares.threshold = threshold
      }
