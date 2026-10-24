module Parun.Types.Shows where

import qualified Parun.Types.Audience as Audience
import qualified Parun.Types.ShownCards as ShownCards

-- | CR 401.5 / 400.2: the payload of Parun.Types.PlayerEffect's Shows arm.
data Shows = MkShows
  { cards :: ShownCards.ShownCards,
    to :: Audience.Audience
  }
  deriving (Eq, Ord, Show)
