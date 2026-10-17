module Pawl.Codec.SeatViewSpec where

import qualified Data.Map.Strict as Map
import qualified Pawl.Codec.ObjectViewSpec as ObjectViewSpec
import qualified Pawl.Codec.SeatView as SeatView
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Mana as Mana
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.SeatView as SeatView

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.SeatView" $ do
  Spec.it s "every key" $
    Common.assertCodec
      s
      SeatView.codec
      testSeat
      testSeatJson
  Spec.it s "has a schema" $ Common.assertHasSchema s SeatView.codec

-- A seat whose hand shows one of its three cards.
testSeat :: SeatView.SeatView
testSeat =
  SeatView.MkSeatView
    { SeatView.player = PlayerId.MkPlayerId 0,
      SeatView.life = 20,
      SeatView.counters = Map.empty,
      SeatView.handSize = 3,
      SeatView.hand = [ObjectViewSpec.hidden],
      SeatView.librarySize = 40,
      SeatView.library = [],
      SeatView.graveyard = [],
      SeatView.exile = [],
      SeatView.manaPool = Mana.MkMana []
    }

testSeatJson :: String
testSeatJson =
  "{\"player\":0,\"life\":20,\"counters\":[],\"handSize\":3,\"hand\":["
    <> hiddenJson
    <> "],\"librarySize\":40,\"library\":[],\"graveyard\":[],\"exile\":[],\"manaPool\":[]}"

hiddenJson :: String
hiddenJson = "{\"object\":7,\"owner\":0,\"controller\":1,\"tapped\":true,\"damage\":2,\"counters\":[],\"attachedTo\":null,\"characteristics\":null}"
