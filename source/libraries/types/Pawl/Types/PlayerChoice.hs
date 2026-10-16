module Pawl.Types.PlayerChoice where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.Gift as Gift

-- | Which of an object's chosen players: the key of Object.chosenPlayers, and
-- what PlayerRef.ChosenPlayerOfBound asks for.
data PlayerChoice
  = -- | CR 614.1c: the player chosen as the object entered (Stuffy Doll).
    AsEnters
  | -- | CR 702.174a: the opponent the nth instance of this gift, counting from
    -- 1, was promised to.
    Promised Gift.Gift Natural.Natural
  deriving (Eq, Ord, Show)
