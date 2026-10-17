{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.EventExpiry where

import qualified Pawl.Codec.DurationEvent as DurationEvent
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.EventExpiry as EventExpiry

-- | A bare object keyed by the record's field names, Pawl.Codec.PaidExpiry's shape.
codec :: Codec.Codec EventExpiry.EventExpiry
codec = Fields.object $ do
  controller <- Fields.required "controller" PlayerId.codec EventExpiry.controller
  event <- Fields.required "event" DurationEvent.codec EventExpiry.event
  pure EventExpiry.MkEventExpiry {EventExpiry.controller = controller, EventExpiry.event = event}
