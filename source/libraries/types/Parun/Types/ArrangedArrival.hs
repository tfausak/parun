module Parun.Types.ArrangedArrival where

import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.PlayerRef as PlayerRef

-- | The payload of Parun.Types.LibraryPlacement's ArrangedBy arm: the end the
-- cards arrive at, and WHO orders them. Parun.Types.ArrangeInLibrary's chooser,
-- for cards that cross into the library rather than stay in it.
data ArrangedArrival = MkArrangedArrival
  { position :: LibraryPosition.LibraryPosition,
    chooser :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
