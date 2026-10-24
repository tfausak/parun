module Parun.Codec.PlayerViewSpec where

import qualified Parun.Codec.PlayerView as PlayerView
import qualified Parun.Codec.SeatViewSpec as SeatViewSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerView as PlayerView
import qualified Parun.Types.Result as Result

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerView" $ do
  Spec.it s "every key" $
    Common.assertCodec s PlayerView.codec testView testViewJson
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerView.codec

testView :: PlayerView.PlayerView
testView =
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
      PlayerView.witnessedLastTurn = [],
      PlayerView.result = Just (Result.Won (PlayerId.MkPlayerId 1))
    }

testViewJson :: String
testViewJson =
  "{\"viewer\":0,\"turn\":3,\"phase\":{\"type\":\"PrecombatMain\"},\"active\":1,\"priority\":1,\"seats\":["
    <> SeatViewSpec.testSeatJson
    <> "],\"battlefield\":[],\"stack\":[],\"witnessed\":[],\"witnessedLastTurn\":[],\"result\":"
    <> wonJson
    <> "}"

wonJson :: String
wonJson = "{\"type\":\"Won\",\"value\":1}"
