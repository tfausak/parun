module Parun.Types.Status where

import qualified Parun.Types.Departure as Departure

data Status
  = Playing
  | Departed Departure.Departure
  deriving (Eq, Ord, Show)
