module Parun.Types.Batching where

-- | CR 603.2c: whether a trigger event is each occurrence or the whole
-- simultaneous batch. Not a Bool.
data Batching
  = -- | "Whenever a player gains life": once per occurrence.
    EachOccurrence
  | -- | "Whenever one or more players gain life": once per batch.
    OneOrMore
  deriving (Bounded, Enum, Eq, Ord, Show)
