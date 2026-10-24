module Parun.Types.SplitMix where

import qualified Data.Word as Word

-- | SplitMix64's state, which chance and the random bot draw from. Seeded by
-- using the seed as the state.
newtype SplitMix = MkSplitMix
  { unwrap :: Word.Word64
  }
  deriving (Eq, Show)
