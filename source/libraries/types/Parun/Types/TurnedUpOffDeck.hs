module Parun.Types.TurnedUpOffDeck where

import qualified Data.Set as Set
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SideDeck as SideDeck

-- | The payload of Parun.Types.GameEvent's TurnedUpOffDeck arm: a player moved
-- the top card of a side deck off it and turned it face up -- CR 701.32b's set
-- in motion off a scheme deck, CR 701.31b's planeswalk and CR 901.10's turn-up
-- off a planar deck, which CR 312.5 calls encountering a phenomenon. Off a
-- planar deck the move IS the planeswalk (CR 901.11), and 'card' is what the
-- player planeswalked to (CR 701.31d).
data TurnedUpOffDeck = MkTurnedUpOffDeck
  { deck :: SideDeck.SideDeck,
    player :: PlayerId.PlayerId,
    card :: ObjectId.ObjectId,
    -- | CR 701.31d / 901.11b: the plane and phenomenon cards the player
    -- planeswalked away from, each by the id it had face up -- the ones turned
    -- face down or that left the game. Empty off a scheme deck.
    awayFrom :: Set.Set ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
