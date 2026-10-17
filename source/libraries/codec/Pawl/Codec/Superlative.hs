{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Superlative where

import qualified Pawl.Codec.Comparison as Comparison
import qualified Pawl.Codec.PlayerMeasure as PlayerMeasure
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Superlative as Superlative

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec Superlative.Superlative
codec = Fields.object $ do
  measure <- Fields.required "measure" PlayerMeasure.codec Superlative.measure
  comparison <- Fields.required "comparison" Comparison.codec Superlative.comparison
  pure Superlative.MkSuperlative {Superlative.measure = measure, Superlative.comparison = comparison}
