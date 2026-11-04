module Parun.Types.BlocksDeclared where

import qualified Data.Set as Set
import qualified Parun.Types.ObjectId as ObjectId

-- | CR 509.1i read the other way: a blocking creature, and the attackers it
-- blocked in that declaration, or blocks now that an effect made it block anew
-- (CR 509.3a). The attackers are carried for CR 509.3e's count, which a
-- filtered trigger takes over the ones its Filter admits.
data BlocksDeclared = MkBlocksDeclared
  { blocker :: ObjectId.ObjectId,
    blocked :: Set.Set ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
