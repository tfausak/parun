{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Drew where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Drew as Drew

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec Drew.Drew
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec Drew.player
  nth <- Fields.required "nth" Common.natural Drew.nth
  pure
    Drew.MkDrew
      { Drew.player = player,
        Drew.nth = nth
      }
