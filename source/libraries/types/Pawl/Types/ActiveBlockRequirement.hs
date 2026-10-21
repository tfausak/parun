module Pawl.Types.ActiveBlockRequirement where

import qualified Pawl.Types.Expiry as Expiry
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.RestrictedCreatures as RestrictedCreatures
import qualified Pawl.Types.Timestamp as Timestamp

-- | CR 509.1c / 613.11: a stored, resolution-generated BLOCKING REQUIREMENT,
-- held in GameState.blockRequirements. The block-axis analogue of
-- ActivePlayerEffect: the printed carrier (Pawl.Types.BlockRequirement) is
-- re-derived live from the battlefield, while these are stored because the
-- object that made them may be long gone. CR 702.39a's provoke and Alluring
-- Scent are producers.
--
-- The subject axis is Pawl.Types.ActiveAttackRequirement's: a Named id the
-- resolution froze (provoke TARGETS its creature, CR 115.1), or a Matching class
-- CR 611.2c keeps dynamic (Alluring Scent's "all creatures able to block"). The
-- attacker is a bare ObjectId: every producer targets it.
--
-- `expiry` decides when a Pawl.Engine.Expiry sweep drops it (CR 514.2, 611.2a,
-- 611.2b); provoke's "this combat" arms Expiry.AtEndOf CombatPhase.
--
-- `timestamp` is stored for ActivePlayerEffect's reason: CR 613.11 orders by
-- timestamp (CR 613.7), and nothing observes it yet because two requirements
-- cannot conflict -- CR 509.1c counts them and never resolves them against each
-- other.
--
-- Runtime-only: card data writes the printed carrier, never one of these. It
-- does have a codec (Pawl.Codec.ActiveBlockRequirement), because a game in
-- progress has to be writable to JSON (#126).
data ActiveBlockRequirement = MkActiveBlockRequirement
  { source :: ObjectId.ObjectId,
    -- | CR 109.5's "you" for a Matching class, baked at resolution:
    -- Pawl.Types.ActiveAttackRequirement's reason.
    controller :: PlayerId.PlayerId,
    timestamp :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry,
    -- | The creatures that must block -- CR 509.1c's subject axis.
    blocker :: RestrictedCreatures.RestrictedCreatures ObjectId.ObjectId,
    -- | The attacking creature it must block.
    attacker :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
