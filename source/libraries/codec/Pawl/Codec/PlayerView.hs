{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.PlayerView where

import qualified Pawl.Codec.LoggedEvent as LoggedEvent
import qualified Pawl.Codec.ObjectView as ObjectView
import qualified Pawl.Codec.Phase as Phase
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.Result as Result
import qualified Pawl.Codec.SeatView as SeatView
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.PlayerView as PlayerView

-- | A bare object keyed by the record's field names: what a client is sent
-- in place of the game state.
codec :: Codec.Codec PlayerView.PlayerView
codec = Fields.object $ do
  viewer <- Fields.required "viewer" PlayerId.codec PlayerView.viewer
  turn <- Fields.required "turn" Common.natural PlayerView.turn
  phase <- Fields.required "phase" Phase.codec PlayerView.phase
  active <- Fields.required "active" PlayerId.codec PlayerView.active
  priority <- Fields.required "priority" (Common.maybe PlayerId.codec) PlayerView.priority
  seats <- Fields.required "seats" (Common.list SeatView.codec) PlayerView.seats
  battlefield <- Fields.required "battlefield" (Common.list ObjectView.codec) PlayerView.battlefield
  stack <- Fields.required "stack" (Common.list ObjectView.codec) PlayerView.stack
  witnessed <- Fields.required "witnessed" (Common.list LoggedEvent.codec) PlayerView.witnessed
  result <- Fields.required "result" (Common.maybe Result.codec) PlayerView.result
  pure
    PlayerView.MkPlayerView
      { PlayerView.viewer = viewer,
        PlayerView.turn = turn,
        PlayerView.phase = phase,
        PlayerView.active = active,
        PlayerView.priority = priority,
        PlayerView.seats = seats,
        PlayerView.battlefield = battlefield,
        PlayerView.stack = stack,
        PlayerView.witnessed = witnessed,
        PlayerView.result = result
      }
