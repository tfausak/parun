module Parun.Types.ChoosePlayerAtRandom where

import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName

-- | CR 608.2d: the payload of Parun.Types.Effect's ChoosePlayerAtRandom arm --
-- which players randomness picks among, and where the pick is bound.
--
-- Parun.Types.ChoosePlayer's twin with the decision replaced by randomness (CR
-- 701.9b), and the SCOPE is the same field for the same reason: it separates
-- Ruhan of the Fomori's "choose an opponent at random" (PlayerScope.Related Opponent)
-- from Strax, Sontaran Nurse's "choose a player at random"
-- (PlayerScope.Related AnyPlayer, which includes the chooser). It is resolved through
-- Parun.Engine.PlayerEffect.playersInScope, the one fold every player-set read
-- shares, against CR 109.5's "you" -- the resolving controller.
data ChoosePlayerAtRandom = MkChoosePlayerAtRandom
  { scope :: PlayerScope.PlayerScope,
    slot :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
