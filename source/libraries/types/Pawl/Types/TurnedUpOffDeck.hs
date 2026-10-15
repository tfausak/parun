module Pawl.Types.TurnedUpOffDeck where

import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.SideDeck as SideDeck

-- | The payload of Pawl.Types.GameEvent's TurnedUpOffDeck arm: a player moved
-- the top card of a side deck off it and turned it face up -- CR 701.32b's set
-- in motion off a scheme deck, CR 701.31b's planeswalk and CR 901.10's turn-up
-- off a planar deck, which CR 312.5 calls encountering a phenomenon.
data TurnedUpOffDeck = MkTurnedUpOffDeck
  { deck :: SideDeck.SideDeck,
    player :: PlayerId.PlayerId,
    card :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
