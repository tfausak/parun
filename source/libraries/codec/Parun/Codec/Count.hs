{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Count where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Aggregation as Aggregation
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Scope as Scope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Count as Count

-- | A BARE OBJECT keyed by the record's field names, the shape every
-- single-constructor record in this codec writes. The "Count" tag belongs to
-- Parun.Codec.Quantity's Count arm -- this codec's only caller -- so the two
-- types never share one tag across two levels.
--
-- Parametric for 'Parun.Codec.Aggregation''s reason, and converts with it.
codec :: (Typeable.Typeable q, Eq q) => Codec.Codec q -> Codec.Codec (Count.Count q)
codec quantityCodec = Fields.object $ do
  scope <- Fields.required "scope" Scope.codec Count.scope
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) Count.filter
  aggregation <- Fields.required "aggregation" (Aggregation.codec quantityCodec) Count.aggregation
  pure
    Count.MkCount
      { Count.scope = scope,
        Count.filter = filter_,
        Count.aggregation = aggregation
      }
