{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Measures where

import qualified Parun.Codec.Comparison as Comparison
import qualified Parun.Codec.Measure as Measure
import qualified Parun.Codec.Operand as Operand
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Measures as Measures

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Filter's Measures arm.
codec :: Codec.Codec Measures.Measures
codec = Fields.object $ do
  measure <- Fields.required "measure" Measure.codec Measures.measure
  comparison <- Fields.required "comparison" Comparison.codec Measures.comparison
  operand <- Fields.required "operand" Operand.codec Measures.operand
  pure
    Measures.MkMeasures
      { Measures.measure = measure,
        Measures.comparison = comparison,
        Measures.operand = operand
      }
