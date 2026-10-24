module Parun.Types.RevealObligation where

-- | CR 603.11: whether a draw-time reveal's static half instructs the reveal
-- (Rowen's "reveal the first card you draw each turn") or allows it (God-Eternal
-- Kefnet's "you may reveal"). Parun.Types.CastObligation's shape, for a reveal.
data RevealObligation
  = Mandatory
  | -- | CR 121.9: the player looks at the card before choosing.
    Optional
  deriving (Bounded, Enum, Eq, Ord, Show)
