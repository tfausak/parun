module Pawl.Types.ControlMargin where

import qualified Numeric.Natural as Natural

-- | How many permanents matching Filter.Controls' filter the candidate player
-- must control (CR 110.2): a count of its own, or a margin over the
-- perspective player's (CR 109.5).
data ControlMargin
  = -- | At least this many -- Disorder's "each player who controls a white creature" at 1.
    AtLeast Natural.Natural
  | -- | At least this many more than "you" -- Oreskos Explorer's "more lands than you" at 1.
    MoreThanYou Natural.Natural
  deriving (Eq, Ord, Show)
