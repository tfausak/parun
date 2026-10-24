module Parun.Types.TypesAre where

import qualified Data.Set as Set
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Reference as Reference

-- | CR 205.2a: an object's card types, all of them.
data TypesAre = MkTypesAre
  { object :: Reference.Reference,
    types :: Set.Set CardType.CardType
  }
  deriving (Eq, Ord, Show)
