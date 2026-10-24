{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RemovePlayerCounters where

import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RemovePlayerCounters as RemovePlayerCounters

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's RemovePlayerCounters arm. The tally slot is
-- ELIDED when absent, Parun.Codec.RemoveCounters' posture, so a removal that
-- nothing looks back at writes only the three keys it always did.
codec :: Codec.Codec RemovePlayerCounters.RemovePlayerCounters
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec RemovePlayerCounters.player
  kind <- Fields.required "kind" PlayerCounterKind.codec RemovePlayerCounters.kind
  quantity <- Fields.required "quantity" Quantity.codec RemovePlayerCounters.quantity
  tally <- Fields.defaulted "tally" Nothing (Common.maybe SlotName.codec) RemovePlayerCounters.tally
  pure
    RemovePlayerCounters.MkRemovePlayerCounters
      { RemovePlayerCounters.player = player,
        RemovePlayerCounters.kind = kind,
        RemovePlayerCounters.quantity = quantity,
        RemovePlayerCounters.tally = tally
      }
