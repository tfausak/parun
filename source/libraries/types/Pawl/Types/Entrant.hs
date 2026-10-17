module Pawl.Types.Entrant where

import qualified Data.Text as Text
import qualified Pawl.Types.Label as Label

-- | CR 103: one player entering a new game, with the deck they bring as the
-- lines of a deck list (Pawl.DeckList).
data Entrant = MkEntrant
  { name :: Label.Label,
    deck :: [Text.Text]
  }
  deriving (Eq, Ord, Show)
