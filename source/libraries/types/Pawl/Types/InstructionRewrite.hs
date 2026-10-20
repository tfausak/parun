module Pawl.Types.InstructionRewrite where

import qualified Pawl.Types.Scaling as Scaling

-- | CR 614.1a: how a replacement rewrites a player's instruction to do something
-- some number of times (Pawl.Types.PlayerInstruction).
data InstructionRewrite
  = -- | The instruction is resized, and stays STANDING at the new count, so CR
    -- 616.2's next iteration re-collects against it and a second such row
    -- rescales what the first left. Krark's Thumb's "flip two coins", Tekuthal,
    -- Inquiry Dominus's "proliferate twice" and Bruvac the Grandiloquent's "twice
    -- that many" are Multiply 2; Kenessos, Priest of Thassa's "that many plus
    -- one" and The Valeyard's "an additional time" (CR 701.55c) are AddMore 1.
    Scaled Scaling.Scaling
  | -- | Eligeth, Crossroads Augur's "draw that many cards instead" (CR 614.6):
    -- the instruction does not happen, and an instruction to draw its count
    -- does, proposed as an event of its own (CR 121.2a).
    DrawInstead
  | -- | Pokey, the Scallywagg's "you may instead roll a d20. 1-10 is tails and
    -- 11-20 is heads" (CR 614.1a / 614.6): one coin's flip does not happen, and a
    -- d20 roll does, read back as the flip's face. Counts as rolling a die.
    RollD20Instead
  deriving (Eq, Ord, Show)
