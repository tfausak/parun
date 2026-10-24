{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CardPutIntoGraveyard where

import qualified Data.Set as Set
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CardPutIntoGraveyard as CardPutIntoGraveyard

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.CardLeavesZone is. The origin zones are defaulted, most printings
-- naming none.
codec :: Codec.Codec CardPutIntoGraveyard.CardPutIntoGraveyard
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) CardPutIntoGraveyard.filter
  from <- Fields.defaulted "from" Set.empty (Common.set Zone.codec) CardPutIntoGraveyard.from
  pure CardPutIntoGraveyard.MkCardPutIntoGraveyard {CardPutIntoGraveyard.filter = filter_, CardPutIntoGraveyard.from = from}
