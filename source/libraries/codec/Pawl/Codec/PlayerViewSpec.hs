module Pawl.Codec.PlayerViewSpec where

import qualified Pawl.Codec.PlayerView as PlayerView
import qualified Pawl.Codec.SeatViewSpec as SeatViewSpec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.Result as Result

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlayerView" $ do
  Spec.it s "every key" $
    Common.assertCodec
      s
      PlayerView.codec
      PlayerView.MkPlayerView
        { PlayerView.viewer = PlayerId.MkPlayerId 0,
          PlayerView.turn = 3,
          PlayerView.phase = Phase.PrecombatMain,
          PlayerView.active = PlayerId.MkPlayerId 1,
          PlayerView.priority = Just (PlayerId.MkPlayerId 1),
          PlayerView.seats = [SeatViewSpec.testSeat],
          PlayerView.battlefield = [],
          PlayerView.stack = [],
          PlayerView.witnessed = [],
          PlayerView.result = Just (Result.Won (PlayerId.MkPlayerId 1))
        }
      ( "{\"viewer\":0,\"turn\":3,\"phase\":{\"type\":\"PrecombatMain\"},\"active\":1,\"priority\":1,\"seats\":["
          <> SeatViewSpec.testSeatJson
          <> "],\"battlefield\":[],\"stack\":[],\"witnessed\":[],\"result\":"
          <> wonJson
          <> "}"
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerView.codec

wonJson :: String
wonJson = "{\"type\":\"Won\",\"value\":1}"
