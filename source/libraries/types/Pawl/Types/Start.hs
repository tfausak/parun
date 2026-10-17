module Pawl.Types.Start where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Pawl.Types.Board as Board
import qualified Pawl.Types.Entrant as Entrant

-- | Where a scenario's game begins.
data Start
  = -- | A board placed directly.
    FromBoard Board.Board
  | -- | CR 103: a new game set up from each player's deck, in turn order.
    FromDecks (NonEmpty.NonEmpty Entrant.Entrant)
  deriving (Eq, Ord, Show)
