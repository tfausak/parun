module Pawl.Types.PlayOptions where

import qualified Data.Set as Set
import qualified Data.Word as Word
import qualified Numeric.Natural as Natural

-- | What `pawl play` was asked for, seats numbered from one.
data PlayOptions = MkPlayOptions
  { seed :: Maybe Word.Word64,
    first :: Maybe Natural.Natural,
    bots :: Set.Set Natural.Natural,
    json :: Bool,
    -- | Where to save the game as a scenario.
    save :: Maybe FilePath,
    -- | Whether a person is passed for when passing and mana abilities are all
    -- they could do.
    autoPass :: Bool
  }
  deriving (Eq, Show)

-- | A seeded-from-the-clock game between two people, the first asked for.
none :: PlayOptions
none = MkPlayOptions {seed = Nothing, first = Nothing, bots = Set.empty, json = False, save = Nothing, autoPass = True}
