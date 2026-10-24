{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Milled where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Milled as Milled

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec Milled.Milled
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec Milled.player
  cards <- Fields.required "cards" (Common.seq ObjectId.codec) Milled.cards
  pure
    Milled.MkMilled
      { Milled.player = player,
        Milled.cards = cards
      }
