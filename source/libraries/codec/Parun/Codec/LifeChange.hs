{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeChange where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeChange as LifeChange

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be. Runtime-only: GameEvent serialises transcripts,
-- never card data.
codec :: Codec.Codec LifeChange.LifeChange
codec = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec LifeChange.player
  amount <- Fields.required "amount" Common.natural LifeChange.amount
  pure
    LifeChange.MkLifeChange
      { LifeChange.player = player,
        LifeChange.amount = amount
      }
