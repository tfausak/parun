module Parun.Types.LibraryDeparture where

-- | How a card left a library, as Parun.Types.Filter.LeftLibraryThisTurn asks
-- it. Not a surveil (CR 701.25a) or an explore (CR 701.44a), nor a tutor.
data LibraryDeparture
  = -- | Drawn (CR 121.1) -- Sylvan Library.
    Drawn
  | -- | Milled (CR 701.17a) -- The Master, Transcendent.
    Milled
  deriving (Bounded, Enum, Eq, Ord, Show)
