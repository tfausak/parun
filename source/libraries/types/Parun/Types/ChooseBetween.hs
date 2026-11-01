module Parun.Types.ChooseBetween where

import qualified Numeric.Natural as Natural

-- | A range of how FEW and how MANY may be chosen, both inclusive: CR 700.2's
-- modes ("Choose one or both --" over two modes, Vandalize, is 1 to 2) or CR
-- 105.4's colours ("the color or colors of your choice", Scuttlemutt, is 1 to
-- 5).

-- Both fields are a Natural and the pair is ordered, so they are named rather
-- than positional: a card file that swapped them would state a range no
-- selection can satisfy, and the two would still decode.
--
-- @least <= most@ is an invariant nothing here maintains; Parun.Codec.ChooseBetween
-- rejects a range that breaks it, this being where a range enters the engine.
data ChooseBetween = MkChooseBetween
  { least :: Natural.Natural,
    most :: Natural.Natural
  }
  deriving (Eq, Ord, Show)
