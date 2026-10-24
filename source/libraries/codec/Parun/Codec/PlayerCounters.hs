{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerCounters where

import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerCounters as PlayerCounters

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's GainPlayerCounters arm.
codec :: Codec.Codec PlayerCounters.PlayerCounters
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec PlayerCounters.player
  kind <- Fields.required "kind" PlayerCounterKind.codec PlayerCounters.kind
  quantity <- Fields.required "quantity" Quantity.codec PlayerCounters.quantity
  pure
    PlayerCounters.MkPlayerCounters
      { PlayerCounters.player = player,
        PlayerCounters.kind = kind,
        PlayerCounters.quantity = quantity
      }
