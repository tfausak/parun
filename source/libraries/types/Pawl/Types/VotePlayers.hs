module Pawl.Types.VotePlayers where

import qualified Pawl.Types.SlotName as SlotName

-- | CR 701.38b's players, the payload of Pawl.Types.VoteChoices' Players arm:
-- the listed choices are the players still in the game, and each one's tally is
-- bound at @slot@ for a later effect of the same resolution to read (Mob
-- Verdict's "for each vote an opponent received").
data VotePlayers = MkVotePlayers
  { -- | Mob Verdict's "another player": a voter is not offered themself.
    another :: Bool,
    -- | Where the per-player tally is bound.
    slot :: SlotName.SlotName
  }
  deriving (Eq, Ord, Show)
