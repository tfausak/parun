module Parun.Types.BeginningStep where

data BeginningStep
  = Untap
  | Upkeep
  | DrawStep
  deriving (Bounded, Enum, Eq, Ord, Show)
