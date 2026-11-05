module Parun.Types.TurnScope where

import qualified Parun.Types.PlayerRef as PlayerRef

-- | CR 102.1 / 109.5: whose turn a phase-scoped ability means. "At the
-- beginning of EACH end step" is @Relative AnyPlayer@, "YOUR upkeep" is
-- @Relative You@, Brineborn Cutthroat's "during an OPPONENT's turn" is
-- @Relative Opponent@, and Soul Bleed's "enchanted creature's controller" a
-- reference read from the reader's source.
--
-- CR 109.5 makes "your" mean the controller, and answers separately per ability
-- kind, so a relation names no player and each READER supplies its own: for a
-- triggered ability CR 109.5 and CR 603.3a give the controller when the ability
-- triggered; for an activated one, the CR 602.2 activator. A relation is judged
-- between that seat and the active player directly
-- (Parun.Engine.Turn.turnScopeAdmits), so CR 801's range cuts no turn.
--
-- A CR 603.7 delayed ability keyed to "the NEXT end step" is @Relative
-- AnyPlayer@: any player's end step qualifies, and its once-ness comes from the
-- delayed store (CR 603.7b), never from the scope.
newtype TurnScope
  = -- | CR 102.1: the turn of a player the reference names.
    PlayersTurn PlayerRef.PlayerRef
  deriving (Eq, Ord, Show)
