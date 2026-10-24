module Parun.Types.TapForMana where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaRestriction as ManaRestriction

-- | CR 602.2's "unless the object specifically says otherwise", said by an
-- effect instead of the object: the player may tap matching permanents they
-- don't control for mana (CR 106.12), Piracy.
data TapForMana = MkTapForMana
  { -- | Which permanents the player may tap; read only of ones they don't
    -- control, since their own need no permission.
    permanents :: Filter.Filter Keyword.Keyword,
    -- | CR 106.6: what mana made this way may be spent on, beside any
    -- restriction the tapped permanent's own ability puts on it.
    restriction :: Maybe ManaRestriction.ManaRestriction
  }
  deriving (Eq, Ord, Show)
