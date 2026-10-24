module Parun.Types.DrawReveal where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.RevealObligation as RevealObligation

-- | CR 603.11 / 121.9: a draw-time reveal's static half -- whether it instructs
-- or allows the reveal, and WHICH draw of the turn it reveals: Rowen's "the
-- first card you draw each turn". No ordinal is every draw, Booby Trap's "each
-- card they draw".
data DrawReveal = MkDrawReveal
  { obligation :: RevealObligation.RevealObligation,
    nth :: Maybe Natural.Natural
  }
  deriving (Eq, Ord, Show)
