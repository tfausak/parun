module Parun.Types.RollModifier where

import qualified Numeric.Natural as Natural

-- | CR 706.2b: HOW a modifier reaching a die roll from outside the roll's own
-- instruction changes the natural result. Rule 706.2b sorts every such modifier
-- into exactly two buckets and considers them in that order, so this is the
-- classification that ordering reads.
--
-- A type rather than a payload-free Parun.Types.PlayerEffect arm,
-- Parun.Types.DieRollRewrite's reason one rule over: what the effect WATCHES (a
-- roller, a die size, a natural result) and what it DOES to the number are two
-- independent axes, and Parun.Types.ModifiedRoll carries the first.
--
-- A CLASSIFICATION and never a card: the rules core sorting rule 706.2b's two
-- buckets must ask which bucket a modifier is in, never which card printed it.
data RollModifier
  = -- | CR 706.2b's FIRST step: throw the same die again and take the new number
    -- as the natural result, the old one simply ceasing to be it (Clam-I-Am's
    -- "you may reroll that die").
    --
    -- The discarded number is NOT CR 706.6's ignored roll: that rule treats a
    -- roll as never having happened, while a rerolled die's first result
    -- happened and has already triggered any ability that triggers "whenever a
    -- player rolls one or more dice" (CR 706.7's words).
    Reroll
  | -- | CR 706.2b's SECOND step: increase or decrease the result by this amount,
    -- the direction chosen as the modifier is applied (Night Shift of the Living
    -- Dead's "increase or decrease the result by 1").
    IncreaseOrDecrease Natural.Natural
  deriving (Eq, Ord, Show)
