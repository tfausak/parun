{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RandomCard where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.HiddenZone as HiddenZone
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RandomCard as RandomCard

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes.
--
-- @filter@ and @count@ are defaulted rather than required, so the unnarrowed
-- singular -- Merfolk Spy's and Wild Evocation's "a card at random from their
-- hand" -- writes neither key, and Gate to Seatower's "seek a nonland card"
-- writes its filter alone.
codec :: Codec.Codec RandomCard.RandomCard
codec = Fields.object $ do
  zone <- Fields.required "zone" HiddenZone.codec RandomCard.zone
  player <- Fields.required "player" PlayerRef.codec RandomCard.player
  filter_ <- Fields.defaulted "filter" (Filter.And []) (Filter.codec Keyword.codec) RandomCard.filter
  count <- Fields.defaulted "count" (Quantity.Literal 1) Quantity.codec RandomCard.count
  pure
    RandomCard.MkRandomCard
      { RandomCard.zone = zone,
        RandomCard.player = player,
        RandomCard.filter = filter_,
        RandomCard.count = count
      }
