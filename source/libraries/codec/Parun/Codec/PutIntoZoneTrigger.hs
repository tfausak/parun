{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PutIntoZoneTrigger where

import qualified Data.Set as Set
import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PutIntoZoneTrigger as PutIntoZoneTrigger

-- | A bare object keyed by the record's field names. The destination is
-- required; every other field defaults to PutIntoZoneTrigger.self's and writes
-- no key.
codec :: Codec.Codec PutIntoZoneTrigger.PutIntoZoneTrigger
codec = Fields.object $ do
  card <- Fields.defaulted "card" (PutIntoZoneTrigger.card defaults) ActingPermanent.codec PutIntoZoneTrigger.card
  from <- Fields.defaulted "from" Set.empty (Common.set Zone.codec) PutIntoZoneTrigger.from
  to <- Fields.required "to" Zone.codec PutIntoZoneTrigger.to
  scope <- Fields.defaulted "scope" (PutIntoZoneTrigger.scope defaults) TurnScope.codec PutIntoZoneTrigger.scope
  duringResolution <- Fields.defaulted "duringResolution" False Common.boolean PutIntoZoneTrigger.duringResolution
  batching <- Fields.defaulted "batching" (PutIntoZoneTrigger.batching defaults) Batching.codec PutIntoZoneTrigger.batching
  pure
    PutIntoZoneTrigger.MkPutIntoZoneTrigger
      { PutIntoZoneTrigger.card = card,
        PutIntoZoneTrigger.from = from,
        PutIntoZoneTrigger.to = to,
        PutIntoZoneTrigger.scope = scope,
        PutIntoZoneTrigger.duringResolution = duringResolution,
        PutIntoZoneTrigger.batching = batching
      }
  where
    -- The destination is required, so the zone given here is never read.
    defaults = PutIntoZoneTrigger.self minBound
