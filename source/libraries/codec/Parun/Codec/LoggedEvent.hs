{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LoggedEvent where

import qualified Parun.Codec.EventGroup as EventGroup
import qualified Parun.Codec.GameEvent as GameEvent
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LoggedEvent as LoggedEvent

codec :: Codec.Codec LoggedEvent.LoggedEvent
codec = Fields.object $ do
  group <- Fields.required "group" EventGroup.codec LoggedEvent.group
  event <- Fields.required "event" GameEvent.codec LoggedEvent.event
  pure LoggedEvent.MkLoggedEvent {LoggedEvent.group = group, LoggedEvent.event = event}
