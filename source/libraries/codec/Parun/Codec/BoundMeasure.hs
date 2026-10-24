{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BoundMeasure where

import qualified Parun.Codec.Measure as Measure
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BoundMeasure as BoundMeasure

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec BoundMeasure.BoundMeasure
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec BoundMeasure.slot
  measure <- Fields.required "measure" Measure.codec BoundMeasure.measure
  pure BoundMeasure.MkBoundMeasure {BoundMeasure.slot = slot, BoundMeasure.measure = measure}
