module Parun.Types.Lookback where

-- | CR 608.2i: how far back a look-back read reaches.
data Lookback
  = -- | The turn in progress, GameState.events.
    ThisTurn
  | -- | Since the candidate became the object it is (CR 400.7) -- Palladia-Mors,
    -- the Ruiner's "hasn't dealt damage yet".
    AsThisObject
  deriving (Bounded, Enum, Eq, Ord, Show)
