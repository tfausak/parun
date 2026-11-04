module Parun.Types.AttackerTarget where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 508.3a: what an attacker trigger needs the creature to be attacking.
data AttackerTarget
  = -- | CR 508.3a's first sentence: anything.
    AnyTarget
  | -- | CR 508.5: a defending player in this relation to CR 109.5's "you".
    Defending PlayerRelation.PlayerRelation
  | -- | CR 508.3a's second sentence: a permanent CR 508.1b announced that the
    -- Filter admits.
    Permanent (Filter.Filter Keyword.Keyword)
  | -- | CR 702.105a: the player with the most life or tied for most life.
    PlayerWithMostLife
  deriving (Eq, Ord, Show)
