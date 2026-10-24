module Parun.Types.ChoosePermanents where

import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | CR 608.2d's battlefield choice bound for a later instruction to act on --
-- Archfiend of Depravity's "that player chooses up to two creatures they
-- control, then sacrifices the rest".
data ChoosePermanents = MkChoosePermanents
  { permanents :: ChosenPermanents.ChosenPermanents,
    -- | Where the chosen permanents are bound, as a group; nothing is bound when
    -- none was chosen, so a later Filter.IsBound matches nothing.
    slot :: SlotName.SlotName,
    -- | CR 700.3: Nothing binds the pick itself. Just names the player who then
    -- chooses one of two piles -- the pick, and the rest of the matching
    -- permanents -- and that pile is what is bound: Stand or Fall's "separate
    -- all creatures that player controls into two piles and that player
    -- chooses one". Elided rather than written null.
    pileChooser :: Maybe PlayerRef.PlayerRef
  }
  deriving (Eq, Ord, Show)
