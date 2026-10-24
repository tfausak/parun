{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EventExpiry where

import qualified Parun.Codec.DurationEvent as DurationEvent
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EventExpiry as EventExpiry

-- | A bare object keyed by the record's field names, Parun.Codec.PaidExpiry's shape.
codec :: Codec.Codec EventExpiry.EventExpiry
codec = Fields.object $ do
  controller <- Fields.required "controller" PlayerId.codec EventExpiry.controller
  event <- Fields.required "event" DurationEvent.codec EventExpiry.event
  pure EventExpiry.MkEventExpiry {EventExpiry.controller = controller, EventExpiry.event = event}
