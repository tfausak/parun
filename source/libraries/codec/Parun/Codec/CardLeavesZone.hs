{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CardLeavesZone where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CardLeavesZone as CardLeavesZone

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PermanentSacrificed is. The filter, the scope and the zone left are
-- required: a printing that narrowed by neither of the first two would spell
-- itself out as the trivial Filter and TurnScope.EachTurn rather than leaving
-- either out. The destination and whose pile are defaulted, most printings
-- naming neither.
codec :: Codec.Codec CardLeavesZone.CardLeavesZone
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) CardLeavesZone.filter
  scope <- Fields.required "scope" TurnScope.codec CardLeavesZone.scope
  from <- Fields.required "from" Zone.codec CardLeavesZone.from
  to <- Fields.defaulted "to" Nothing (Common.maybe Zone.codec) CardLeavesZone.to
  whose <- Fields.defaulted "whose" Nothing (Common.maybe PlayerRelation.codec) CardLeavesZone.whose
  pure CardLeavesZone.MkCardLeavesZone {CardLeavesZone.filter = filter_, CardLeavesZone.scope = scope, CardLeavesZone.from = from, CardLeavesZone.to = to, CardLeavesZone.whose = whose}
