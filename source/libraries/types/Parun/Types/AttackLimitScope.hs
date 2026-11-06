module Parun.Types.AttackLimitScope where

import qualified Parun.Types.PlayerScope as PlayerScope

-- | What a scoped bound on attackers counts the attackers OF (CR 508.1c, CR
-- 802.3a): Parun.Types.AttackLimitUnless's `defenders`.
data AttackLimitScope
  = -- | CR 802.3a: the creatures attacking these players, named from CR 109.5's
    -- "you" (Crawlspace's "can attack you").
    Players PlayerScope.PlayerScope
  | -- | CR 306.6 / 310.5: the creatures attacking the permanent holding the
    -- ability (Tomik, Orzhov Lawmage's granted "can attack this planeswalker").
    Source
  deriving (Eq, Ord, Show)
