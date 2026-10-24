module Parun.Types.ChoosePlayer where

import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName

-- | CR 608.2d: the payload of Parun.Types.Effect's ChoosePlayer arm -- which
-- players a resolving effect offers, and where the answer is bound.
--
-- The SCOPE is what separates Skullwinder's "choose an opponent"
-- (PlayerScope.Related Opponent) from Stadium Vendors' "choose a player"
-- (PlayerScope.Related AnyPlayer, which includes the chooser). It is resolved through
-- Parun.Engine.PlayerEffect.playersInScope, the one fold every player-set read
-- shares, against CR 109.5's "you" -- the resolving controller.
data ChoosePlayer = MkChoosePlayer
  { scope :: PlayerScope.PlayerScope,
    slot :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
