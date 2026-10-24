{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EachCardInGraveyard where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ZoneScope as ZoneScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EachCardInGraveyard as EachCardInGraveyard

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec EachCardInGraveyard.EachCardInGraveyard
codec = Fields.object $ do
  graveyards <- Fields.required "graveyards" ZoneScope.codec EachCardInGraveyard.graveyards
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) EachCardInGraveyard.filter
  pure
    EachCardInGraveyard.MkEachCardInGraveyard
      { EachCardInGraveyard.graveyards = graveyards,
        EachCardInGraveyard.filter = filter_
      }
