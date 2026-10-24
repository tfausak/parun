module Parun.Types.SubtypesAre where

import qualified Data.Set as Set
import qualified Parun.Types.Reference as Reference
import qualified Parun.Types.Subtype as Subtype

-- | CR 205.3: an object's subtypes, all of them.
data SubtypesAre = MkSubtypesAre
  { object :: Reference.Reference,
    subtypes :: Set.Set Subtype.Subtype
  }
  deriving (Eq, Ord, Show)
