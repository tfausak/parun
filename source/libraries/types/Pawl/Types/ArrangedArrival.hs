module Pawl.Types.ArrangedArrival where

import qualified Pawl.Types.LibraryPosition as LibraryPosition
import qualified Pawl.Types.PlayerRef as PlayerRef

-- | The payload of Pawl.Types.LibraryPlacement's ArrangedBy arm: the end the
-- cards arrive at, and WHO orders them. Pawl.Types.ArrangeInLibrary's chooser,
-- for cards that cross into the library rather than stay in it.
data ArrangedArrival = MkArrangedArrival
  { position :: LibraryPosition.LibraryPosition,
    chooser :: PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
