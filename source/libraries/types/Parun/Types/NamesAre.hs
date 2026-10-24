module Parun.Types.NamesAre where

import qualified Data.Set as Set
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Reference as Reference

-- | CR 201.1: an object's names, all of them; none for a nameless object.
data NamesAre = MkNamesAre
  { object :: Reference.Reference,
    names :: Set.Set CardName.CardName
  }
  deriving (Eq, Ord, Show)
