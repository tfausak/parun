{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RandomCardInGraveyard where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.ZoneScope as ZoneScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RandomCardInGraveyard as RandomCardInGraveyard

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes.
--
-- @filter@ and @count@ are defaulted rather than required, so the unnarrowed
-- singular writes neither key; @players@ is required, since no scope is the
-- printed default.
codec :: Codec.Codec RandomCardInGraveyard.RandomCardInGraveyard
codec = Fields.object $ do
  players <- Fields.required "players" ZoneScope.codec RandomCardInGraveyard.players
  filter_ <- Fields.defaulted "filter" (Filter.And []) (Filter.codec Keyword.codec) RandomCardInGraveyard.filter
  count <- Fields.defaulted "count" (Quantity.Literal 1) Quantity.codec RandomCardInGraveyard.count
  pure
    RandomCardInGraveyard.MkRandomCardInGraveyard
      { RandomCardInGraveyard.players = players,
        RandomCardInGraveyard.filter = filter_,
        RandomCardInGraveyard.count = count
      }
