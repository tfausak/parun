{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RemoveCounters where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RemoveCounters as RemoveCounters

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's RemoveCounters arm. The tally slot is ELIDED
-- when absent, Parun.Codec.Destroy's three bound slots' posture, so a card that
-- looks back at no removal writes only the three keys it always did.
codec :: Codec.Codec RemoveCounters.RemoveCounters
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) RemoveCounters.kind
  quantity <- Fields.required "quantity" Quantity.codec RemoveCounters.quantity
  slot <- Fields.required "slot" SlotName.codec RemoveCounters.slot
  tally <- Fields.defaulted "tally" Nothing (Common.maybe SlotName.codec) RemoveCounters.tally
  pure
    RemoveCounters.MkRemoveCounters
      { RemoveCounters.kind = kind,
        RemoveCounters.quantity = quantity,
        RemoveCounters.slot = slot,
        RemoveCounters.tally = tally
      }
