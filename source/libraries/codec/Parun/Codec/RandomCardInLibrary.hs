{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RandomCardInLibrary where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RandomCardInLibrary as RandomCardInLibrary

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes.
--
-- @filter@ and @count@ are defaulted rather than required, so the unnarrowed
-- singular writes neither key, and Gate to Seatower's "seek a nonland card"
-- writes its filter alone.
codec :: Codec.Codec RandomCardInLibrary.RandomCardInLibrary
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec RandomCardInLibrary.player
  filter_ <- Fields.defaulted "filter" (Filter.And []) (Filter.codec Keyword.codec) RandomCardInLibrary.filter
  count <- Fields.defaulted "count" (Quantity.Literal 1) Quantity.codec RandomCardInLibrary.count
  pure
    RandomCardInLibrary.MkRandomCardInLibrary
      { RandomCardInLibrary.player = player,
        RandomCardInLibrary.filter = filter_,
        RandomCardInLibrary.count = count
      }
