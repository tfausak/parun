module Parun.Types.Undesignate where

import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.ObjectRef as ObjectRef

-- | CR 701.60a and CR 722.3b: the named permanents lose this designation.
data Undesignate = MkUndesignate
  { designation :: Designation.Designation,
    ref :: ObjectRef.ObjectRef
  }
  deriving (Eq, Ord, Show)
