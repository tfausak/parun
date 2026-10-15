{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.TurnedUpOffDeck where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.SideDeck as SideDeck
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.TurnedUpOffDeck as TurnedUpOffDeck

codec :: Codec.Codec TurnedUpOffDeck.TurnedUpOffDeck
codec = Fields.object $ do
  deck <- Fields.required "deck" SideDeck.codec TurnedUpOffDeck.deck
  player <- Fields.required "player" PlayerId.codec TurnedUpOffDeck.player
  card <- Fields.required "card" ObjectId.codec TurnedUpOffDeck.card
  pure TurnedUpOffDeck.MkTurnedUpOffDeck {TurnedUpOffDeck.deck = deck, TurnedUpOffDeck.player = player, TurnedUpOffDeck.card = card}
