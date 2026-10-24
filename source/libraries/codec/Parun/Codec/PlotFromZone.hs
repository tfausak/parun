{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlotFromZone where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.InZone as InZone
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlotFromZone as PlotFromZone

-- | A bare object keyed by the record's field names, Parun.Codec.CastFromZone's
-- shape; the zone reference is Parun.Codec.InZone's, so its CR 400.1 invariant is
-- enforced here too.
codec :: Codec.Codec PlotFromZone.PlotFromZone
codec = Fields.object $ do
  from <- Fields.required "from" InZone.codec PlotFromZone.from
  matching <- Fields.required "matching" (Filter.codec Keyword.codec) PlotFromZone.matching
  pure PlotFromZone.MkPlotFromZone {PlotFromZone.from = from, PlotFromZone.matching = matching}
