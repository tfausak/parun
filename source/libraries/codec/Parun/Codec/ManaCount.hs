{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ManaCount where

import qualified Parun.Codec.ManaFilter as ManaFilter
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ManaCount as ManaCount

-- | A BARE OBJECT keyed by the record's field names, the shape every
-- single-constructor record in this codec writes. The tag that picks it is
-- written by Parun.Codec.Quantity's ManaCount arm, this codec's only caller.
codec :: Codec.Codec ManaCount.ManaCount
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec ManaCount.player
  filter_ <- Fields.required "filter" ManaFilter.codec ManaCount.filter
  pure
    ManaCount.MkManaCount
      { ManaCount.player = player,
        ManaCount.filter = filter_
      }
