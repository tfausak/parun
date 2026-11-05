module Parun.Types.CounteringTrigger where

import qualified Parun.Types.CounteredKind as CounteredKind
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 701.6a: what was countered, and who controlled what countered it (CR
-- 405.4, as of the countering).
data CounteringTrigger = MkCounteringTrigger
  { countered :: CounteredKind.CounteredKind,
    counterer :: PlayerRelation.PlayerRelation
  }
  deriving (Eq, Ord, Show)

-- | "Whenever a spell is countered": any spell, whoever countered it. The
-- codec's defaults.
defaultValue :: CounteringTrigger
defaultValue =
  MkCounteringTrigger
    { countered = CounteredKind.Spell,
      counterer = PlayerRelation.AnyPlayer
    }
