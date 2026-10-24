{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TurnedUpOffDeck where

import qualified Data.Set as Set
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.SideDeck as SideDeck
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TurnedUpOffDeck as TurnedUpOffDeck

codec :: Codec.Codec TurnedUpOffDeck.TurnedUpOffDeck
codec = Fields.object $ do
  deck <- Fields.required "deck" SideDeck.codec TurnedUpOffDeck.deck
  player <- Fields.required "player" PlayerId.codec TurnedUpOffDeck.player
  card <- Fields.required "card" ObjectId.codec TurnedUpOffDeck.card
  awayFrom <- Fields.defaulted "awayFrom" Set.empty (Common.set ObjectId.codec) TurnedUpOffDeck.awayFrom
  pure TurnedUpOffDeck.MkTurnedUpOffDeck {TurnedUpOffDeck.deck = deck, TurnedUpOffDeck.player = player, TurnedUpOffDeck.card = card, TurnedUpOffDeck.awayFrom = awayFrom}
