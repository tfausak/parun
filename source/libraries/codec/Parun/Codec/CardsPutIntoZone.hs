{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CardsPutIntoZone where

import qualified Data.Set as Set
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CardsPutIntoZone as CardsPutIntoZone

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.CardPutIntoGraveyard is. The origin zones are defaulted, "from
-- anywhere" naming none.
codec :: Codec.Codec CardsPutIntoZone.CardsPutIntoZone
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) CardsPutIntoZone.filter
  scope <- Fields.required "scope" TurnScope.codec CardsPutIntoZone.scope
  from <- Fields.defaulted "from" Set.empty (Common.set Zone.codec) CardsPutIntoZone.from
  to <- Fields.required "to" Zone.codec CardsPutIntoZone.to
  pure CardsPutIntoZone.MkCardsPutIntoZone {CardsPutIntoZone.filter = filter_, CardsPutIntoZone.scope = scope, CardsPutIntoZone.from = from, CardsPutIntoZone.to = to}
