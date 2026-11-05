module Parun.Types.Entrant where

import qualified Data.Text as Text
import qualified Parun.Types.GraveyardOrder as GraveyardOrder
import qualified Parun.Types.Label as Label

-- | CR 103: one player entering a new game, with the deck they bring as the
-- lines of a deck list (Parun.DeckList).
data Entrant = MkEntrant
  { name :: Label.Label,
    deck :: [Text.Text],
    -- | CR 404.3: whether the player arranges cards put into their graveyard
    -- at the same time.
    graveyardOrder :: GraveyardOrder.GraveyardOrder
  }
  deriving (Eq, Ord, Show)
