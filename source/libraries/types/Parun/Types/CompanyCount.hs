module Parun.Types.CompanyCount where

import qualified Numeric.Natural as Natural

-- | How much company a CR 508.1c or CR 509.1b "alone" restriction demands of the
-- declaration holding its creature.
data CompanyCount
  = -- | At least this many others (Bonded Construct's one, Orcish Conscripts' two).
    AtLeastOthers Natural.Natural
  | -- | CR 506.5: none, "can only attack alone" (Errantry).
    NoOthers
  deriving (Eq, Ord, Show)
