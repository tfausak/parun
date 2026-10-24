module Parun.Types.Entrant where

import qualified Data.Text as Text
import qualified Parun.Types.Label as Label

-- | CR 103: one player entering a new game, with the deck they bring as the
-- lines of a deck list (Parun.DeckList).
data Entrant = MkEntrant
  { name :: Label.Label,
    deck :: [Text.Text]
  }
  deriving (Eq, Ord, Show)
