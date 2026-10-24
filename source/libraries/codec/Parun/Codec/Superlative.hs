{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Superlative where

import qualified Parun.Codec.Comparison as Comparison
import qualified Parun.Codec.PlayerMeasure as PlayerMeasure
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Superlative as Superlative

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec Superlative.Superlative
codec = Fields.object $ do
  measure <- Fields.required "measure" PlayerMeasure.codec Superlative.measure
  comparison <- Fields.required "comparison" Comparison.codec Superlative.comparison
  pure Superlative.MkSuperlative {Superlative.measure = measure, Superlative.comparison = comparison}
