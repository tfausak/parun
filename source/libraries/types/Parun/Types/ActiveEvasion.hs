module Parun.Types.ActiveEvasion where

import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 509.1b / 611.2c: a stored, resolution-generated restriction that the
-- attackers 'affected' describes can't be blocked by the creatures 'blockers'
-- describes, held in GameState.evasions. Veiling Oddity's "creatures can't be
-- blocked this turn" and Space Beleren's +1 are the producers.
--
-- Read at Parun.Engine.CombatRestriction.storedEvasions, which `barredBlocks`
-- unions beside the printed Parun.Types.CantBeBlockedBy rows, so
-- Parun.Engine.Combat never learns which road a restriction took. 'affected' is
-- re-read against the live board at each declaration, as
-- Parun.Types.ActiveAttackProhibition's Matching arm is.
--
-- OUTSIDE the layer system (CR 613.11), and `controller` is STORED, both for
-- ActiveAttackProhibition's reasons. `timestamp` is stored for
-- ActiveObjectProhibition's reason, and nothing observes it.
--
-- Runtime-only: card data writes Parun.Types.ForbidBeingBlocked, never one of
-- these. It has a codec (Parun.Codec.ActiveEvasion) because a game in progress
-- has to be writable to JSON (#126).
data ActiveEvasion = MkActiveEvasion
  { source :: ObjectId.ObjectId,
    controller :: PlayerId.PlayerId,
    timestamp :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry,
    affected :: Filter.Filter Keyword.Keyword,
    -- | The blockers barred from each such attacker, matched in the attacker's
    -- context (Parun.Types.ForbidBeingBlocked's 'blockers').
    blockers :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
