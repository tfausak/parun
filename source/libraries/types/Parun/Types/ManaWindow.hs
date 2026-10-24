module Parun.Types.ManaWindow where

import Parun.Types.GameState (GameState)
import qualified Parun.Types.ManaActivation as ManaActivation
import qualified Parun.Types.ManaSegment as ManaSegment
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.PlayerId as PlayerId

-- | A CR 605.3a mana window that has closed, as CR 733.1 needs it to reverse
-- the action it was opened in: whose it was, what they activated, and the
-- states it opened and closed on. Parun.Engine.Cost.reverseIllegal reads it.
--
-- Deliberately no codec: a payment in flight is never serialised.
data ManaWindow = MkManaWindow
  { -- | The player the window was offered to.
    payer :: PlayerId.PlayerId,
    -- | The mana abilities the payer activated in it, nested ones included,
    -- in the order they finished.
    activated :: [ManaActivation.ManaActivation],
    -- | What each of them wrote, oldest first.
    segments :: [ManaSegment.ManaSegment],
    -- | The mana the window's own payment took from the pool, empty unless it
    -- paid.
    spent :: [ManaUnit.ManaUnit],
    -- | The state the window opened on.
    opened :: GameState,
    -- | The state it closed on, before a symbol of the cost was paid.
    closed :: GameState,
    -- | Not a mana window at all but a stretch of a combat toll's payment that
    -- CR 733.1 forbids reversing (Parun.Engine.Cost.unreversibleStretch): it
    -- stands, and nobody is asked about it.
    unreversible :: Bool
  }
