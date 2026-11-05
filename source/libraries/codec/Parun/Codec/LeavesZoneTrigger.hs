{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LeavesZoneTrigger where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LeavesZoneTrigger as LeavesZoneTrigger

-- | A bare object keyed by the record's field names. The zone left is
-- required; every other field defaults to LeavesZoneTrigger.self's and writes
-- no key.
codec :: Codec.Codec LeavesZoneTrigger.LeavesZoneTrigger
codec = Fields.object $ do
  card <- Fields.defaulted "card" (LeavesZoneTrigger.card defaults) ActingPermanent.codec LeavesZoneTrigger.card
  from <- Fields.required "from" Zone.codec LeavesZoneTrigger.from
  to <- Fields.defaulted "to" (LeavesZoneTrigger.to defaults) (Common.maybe Zone.codec) LeavesZoneTrigger.to
  whose <- Fields.defaulted "whose" (LeavesZoneTrigger.whose defaults) (Common.maybe PlayerRelation.codec) LeavesZoneTrigger.whose
  scope <- Fields.defaulted "scope" (LeavesZoneTrigger.scope defaults) TurnScope.codec LeavesZoneTrigger.scope
  batching <- Fields.defaulted "batching" (LeavesZoneTrigger.batching defaults) Batching.codec LeavesZoneTrigger.batching
  pure
    LeavesZoneTrigger.MkLeavesZoneTrigger
      { LeavesZoneTrigger.card = card,
        LeavesZoneTrigger.from = from,
        LeavesZoneTrigger.to = to,
        LeavesZoneTrigger.whose = whose,
        LeavesZoneTrigger.scope = scope,
        LeavesZoneTrigger.batching = batching
      }
  where
    -- The origin is required, so the zone given here is never read.
    defaults = LeavesZoneTrigger.self minBound
