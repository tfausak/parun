module Pawl.Types.Shows where

import qualified Pawl.Types.Audience as Audience
import qualified Pawl.Types.ShownCards as ShownCards

-- | CR 401.5 / 400.2: the payload of Pawl.Types.PlayerEffect's Shows arm.
data Shows = MkShows
  { cards :: ShownCards.ShownCards,
    to :: Audience.Audience
  }
  deriving (Eq, Ord, Show)
