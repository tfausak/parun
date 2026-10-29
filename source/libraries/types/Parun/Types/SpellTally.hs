module Parun.Types.SpellTally where

import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.WhichTurn as WhichTurn

-- | CR 601.2i / 608.2i: how many spells a player cast during a turn, the payload
-- of Parun.Types.Quantity's SpellsCast.
data SpellTally = MkSpellTally
  { player :: PlayerRef.PlayerRef,
    turn :: WhichTurn.WhichTurn
  }
  deriving (Eq, Ord, Show)
