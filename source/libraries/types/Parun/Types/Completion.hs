module Parun.Types.Completion where

import qualified Parun.Types.Announcement as Announcement
import qualified Parun.Types.StateDigest as StateDigest

-- | CR 732.1: what an activation was completed with, the part of its game
-- choice Action.Activate and Action.ActivateManaAbility do not carry.
-- Loop-local (Parun.Types.LoopTrail), so no codec.
data Completion = MkCompletion
  { -- | CR 602.2b / 601.2b-f: what it was announced with; Nothing for a mana
    -- ability activated with priority (CR 605.3a), whose choices `paid` holds.
    announcement :: Maybe Announcement.Announcement,
    -- | CR 601.2g/h: the payment, as the state it left
    -- (Parun.Engine.Fragmented.paid).
    paid :: StateDigest.StateDigest
  }
  deriving (Eq, Ord, Show)
