{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ManifestedDread where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ManifestedDread as ManifestedDread

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec ManifestedDread.ManifestedDread
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec ManifestedDread.player
  cards <- Fields.required "cards" (Common.seq ObjectId.codec) ManifestedDread.cards
  pure
    ManifestedDread.MkManifestedDread
      { ManifestedDread.player = player,
        ManifestedDread.cards = cards
      }
