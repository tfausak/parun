{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ControlClock where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControlClock as ControlClock
import qualified Parun.Types.PlayerId as PlayerId.Type

codec :: Codec.Codec ControlClock.ControlClock
codec = Arm.enum

-- | CR 702.30a's clock for one seat. A pair through 'Parun.JsonCodec.Common.keyedList',
-- an object key having to be a string. Shared by Parun.Types.Object.controlClock and
-- Parun.Types.LastKnown.controlClock, which hold the same map.
entry :: Codec.Codec (PlayerId.Type.PlayerId, ControlClock.ControlClock)
entry = Fields.object $ do
  player <- Fields.required "player" PlayerId.codec fst
  clock <- Fields.required "clock" codec snd
  pure (player, clock)
