{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LeavesTrigger where

import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.LeavingPermanent as LeavingPermanent
import qualified Parun.Codec.OwnedZone as OwnedZone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LeavesTrigger as LeavesTrigger

-- | A bare object keyed by the record's field names. The source, any
-- destination and EachOccurrence write no key (LeavesTrigger.defaultValue).
codec :: Codec.Codec LeavesTrigger.LeavesTrigger
codec = Fields.object $ do
  permanent <- Fields.defaulted "permanent" (LeavesTrigger.permanent LeavesTrigger.defaultValue) LeavingPermanent.codec LeavesTrigger.permanent
  destinations <- Fields.defaulted "destinations" (LeavesTrigger.destinations LeavesTrigger.defaultValue) (Common.set OwnedZone.codec) LeavesTrigger.destinations
  batching <- Fields.defaulted "batching" (LeavesTrigger.batching LeavesTrigger.defaultValue) Batching.codec LeavesTrigger.batching
  pure
    LeavesTrigger.MkLeavesTrigger
      { LeavesTrigger.permanent = permanent,
        LeavesTrigger.destinations = destinations,
        LeavesTrigger.batching = batching
      }
