{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerView where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.LoggedEvent as LoggedEvent
import qualified Parun.Codec.ObjectView as ObjectView
import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Result as Result
import qualified Parun.Codec.SeatView as SeatView
import qualified Parun.Codec.Undoing as Undoing
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerView as PlayerView

-- | A bare object keyed by the record's field names: what a client is sent
-- in place of the game state.
codec :: Codec.Codec PlayerView.PlayerView
codec = Fields.object $ do
  viewer <- Fields.required "viewer" PlayerId.codec PlayerView.viewer
  game <- Fields.required "game" Common.natural PlayerView.game
  turn <- Fields.required "turn" Common.natural PlayerView.turn
  phase <- Fields.required "phase" Phase.codec PlayerView.phase
  active <- Fields.required "active" PlayerId.codec PlayerView.active
  priority <- Fields.required "priority" (Common.maybe PlayerId.codec) PlayerView.priority
  seats <- Fields.required "seats" (Common.list SeatView.codec) PlayerView.seats
  battlefield <- Fields.required "battlefield" (Common.list ObjectView.codec) PlayerView.battlefield
  stack <- Fields.required "stack" (Common.list ObjectView.codec) PlayerView.stack
  parkedStacks <- Fields.defaulted "parkedStacks" Map.empty (Common.naturalMap Common.natural (Common.list ObjectView.codec)) PlayerView.parkedStacks
  witnessed <- Fields.required "witnessed" (Common.list LoggedEvent.codec) PlayerView.witnessed
  witnessedLastTurn <- Fields.required "witnessedLastTurn" (Common.list LoggedEvent.codec) PlayerView.witnessedLastTurn
  result <- Fields.required "result" (Common.maybe Result.codec) PlayerView.result
  undone <- Fields.required "undone" (Common.maybe Undoing.codec) PlayerView.undone
  pure
    PlayerView.MkPlayerView
      { PlayerView.viewer = viewer,
        PlayerView.game = game,
        PlayerView.turn = turn,
        PlayerView.phase = phase,
        PlayerView.active = active,
        PlayerView.priority = priority,
        PlayerView.seats = seats,
        PlayerView.battlefield = battlefield,
        PlayerView.stack = stack,
        PlayerView.parkedStacks = parkedStacks,
        PlayerView.witnessed = witnessed,
        PlayerView.witnessedLastTurn = witnessedLastTurn,
        PlayerView.result = result,
        PlayerView.undone = undone
      }
