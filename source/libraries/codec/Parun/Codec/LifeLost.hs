{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeLost where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeLost as LifeLost

-- | A bare object keyed by the record's field names. Runtime-only: GameEvent
-- serialises transcripts, never card data.
codec :: Codec.Codec LifeLost.LifeLost
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec LifeLost.player
  amount <- Fields.required "amount" Common.natural LifeLost.amount
  first <- Fields.required "first" Common.boolean LifeLost.first
  pure
    LifeLost.MkLifeLost
      { LifeLost.player = player,
        LifeLost.amount = amount,
        LifeLost.first = first
      }
