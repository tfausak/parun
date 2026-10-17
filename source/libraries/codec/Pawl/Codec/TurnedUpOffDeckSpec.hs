module Pawl.Codec.TurnedUpOffDeckSpec where

import qualified Data.Set as Set
import qualified Pawl.Codec.TurnedUpOffDeck as TurnedUpOffDeck
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.SideDeck as SideDeck
import qualified Pawl.Types.TurnedUpOffDeck as TurnedUpOffDeck

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TurnedUpOffDeck" $ do
  Spec.it s "keys the deck, the player and the card" $
    Common.assertCodec
      s
      TurnedUpOffDeck.codec
      (TurnedUpOffDeck.MkTurnedUpOffDeck SideDeck.Scheme (PlayerId.MkPlayerId 1) (ObjectId.MkObjectId 7) Set.empty)
      " {\"card\":7,\"deck\":{\"type\":\"Scheme\"},\"player\":1} "
  Spec.it s "keys the cards planeswalked away from" $
    Common.assertCodec
      s
      TurnedUpOffDeck.codec
      (TurnedUpOffDeck.MkTurnedUpOffDeck SideDeck.Planar (PlayerId.MkPlayerId 1) (ObjectId.MkObjectId 7) (Set.fromList [ObjectId.MkObjectId 3, ObjectId.MkObjectId 5]))
      " {\"awayFrom\":[3,5],\"card\":7,\"deck\":{\"type\":\"Planar\"},\"player\":1} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnedUpOffDeck.codec
