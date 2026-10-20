module Pawl.Types.DiceRoll where

import qualified Numeric.Natural as Natural
import qualified Pawl.Types.PlayerId as PlayerId

-- | The payload of Pawl.Types.ProposedEvent's WouldRollDice arm (CR 706.1 /
-- 614.1a): who rolls, how many dice the instruction throws, and how many of the
-- lowest rolls are then thrown away (CR 706.6).
--
-- A RECORD rather than WouldPerform's bare seat and count, because this event
-- carries TWO numbers of the same type and a caller that transposed them would
-- compile: `dice` is what Pawl.Types.Prompt's RollDie is asked for, and `ignored`
-- is what CR 706.6 discards afterward.
--
-- `roller` is the player rule 706.1's instruction is aimed at -- one of
-- Pawl.Types.RollDie's rollers, each of whose rolls is its own event.
--
-- `dice` is the number the INSTRUCTION names (CR 706.1), never the number it ends
-- up reading: a row that adds a die leaves CR 616.2's next iteration a
-- differently-numbered instruction, WouldPerform's currency and for its reason.
--
-- `ignored` is CR 706.6's count of lowest rolls, zero on every instruction that
-- prints no ignore -- which is every roll in data\/cards\/ today, since the only
-- printings of the word are the replacement effects Pawl.Types.DieRollRewrite
-- carries. NOT the dice that were not rolled: rule 706.6 makes an ignored roll one
-- that HAPPENED and is then treated as never having happened, so the die is
-- thrown and its face asked for either way.
--
-- `sides` is CR 706.1a's N, which Pokey, the Scallywagg's "if you would roll a
-- d20" reads (DieRollRewrite.FlipCoinInstead).
--
-- `forCoin` marks a roll made INSTEAD of a coin flip (InstructionRewrite's
-- RollD20Instead), so the funnel that proposed a roll reads the result back as
-- the flip it stands for: Pokey's "1-10 is tails and 11-20 is heads".
data DiceRoll = MkDiceRoll
  { roller :: PlayerId.PlayerId,
    dice :: Natural.Natural,
    ignored :: Natural.Natural,
    sides :: Natural.Natural,
    forCoin :: Bool
  }
  deriving (Eq, Ord, Show)
