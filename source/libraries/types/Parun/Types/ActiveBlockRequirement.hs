module Parun.Types.ActiveBlockRequirement where

import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RequirementArity as RequirementArity
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 509.1c / 613.11: a stored, resolution-generated BLOCKING REQUIREMENT,
-- held in GameState.blockRequirements. The block-axis analogue of
-- ActivePlayerEffect: the printed carrier (Parun.Types.BlockRequirement) is
-- re-derived live from the battlefield, while these are stored because the
-- object that made them may be long gone. CR 702.39a's provoke and Alluring
-- Scent are producers.
--
-- The subject and attacker axes are Parun.Types.ActiveAttackRequirement's: a
-- Named id the resolution froze (provoke TARGETS its creature, CR 115.1), or a
-- Matching class CR 611.2c keeps dynamic (Alluring Scent's "all creatures able
-- to block", Joraga Invocation's "each creature you control ... must be
-- blocked").
--
-- `expiry` decides when a Parun.Engine.Expiry sweep drops it (CR 514.2, 611.2a,
-- 611.2b); provoke's "this combat" arms Expiry.AtEndOf CombatPhase.
--
-- `timestamp` is stored for ActivePlayerEffect's reason, CR 613.11 ordering by
-- timestamp (CR 613.7), and it also names the RESOLUTION a row came from: the
-- rows one AnySubject requirement stored are one group
-- (Parun.Engine.BlockRequirement's storedGroups).
--
-- Runtime-only: card data writes the printed carrier, never one of these. It
-- does have a codec (Parun.Codec.ActiveBlockRequirement), because a game in
-- progress has to be writable to JSON (#126).
data ActiveBlockRequirement = MkActiveBlockRequirement
  { source :: ObjectId.ObjectId,
    -- | CR 109.5's "you" for a Matching class, baked at resolution:
    -- Parun.Types.ActiveAttackRequirement's reason.
    controller :: PlayerId.PlayerId,
    timestamp :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry,
    -- | The creatures that must block -- CR 509.1c's subject axis.
    blocker :: RestrictedCreatures.RestrictedCreatures ObjectId.ObjectId,
    -- | The attacking creatures to be blocked; Nothing names none.
    attacker :: Maybe (RestrictedCreatures.RestrictedCreatures ObjectId.ObjectId),
    -- | Parun.Types.RequireBlock's `arity`.
    arity :: RequirementArity.RequirementArity
  }
  deriving (Eq, Ord, Show)
