module Parun.Types.MonarchIs where

import qualified Parun.Types.Label as Label

-- | CR 725.1: who the monarch is, if anyone.
newtype MonarchIs = MkMonarchIs
  { player :: Maybe Label.Label
  }
  deriving (Eq, Ord, Show)
