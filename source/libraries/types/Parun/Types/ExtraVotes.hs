module Parun.Types.ExtraVotes where

import qualified Numeric.Natural as Natural

-- | CR 701.38d: the votes beyond rule 701.38a's one that an effect gives a
-- player, and whether the player may decline them.
data ExtraVotes
  = -- | Brago's Representative's "you get an additional vote": cast unasked.
    Mandatory Natural.Natural
  | -- | Ballot Broker's "you may vote an additional time": the voter is asked
    -- (Prompt.OfferedExtra) once per grant, as they vote.
    Optional Natural.Natural
  deriving (Eq, Ord, Show)
