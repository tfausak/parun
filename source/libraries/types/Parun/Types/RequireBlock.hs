module Parun.Types.RequireBlock where

import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.RequirementArity as RequirementArity
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures

-- | The payload of Parun.Types.Effect's RequireBlock arm (#1305): CR 509.1c's
-- requirement that the blockers named block the attackers named, for this
-- duration. The resolution-created twin of Parun.Types.BlockRequirement, on its
-- axes: subject, optional attacker, arity.
--
-- BOTH sides name creatures and the two are NOT interchangeable, so they are
-- named rather than positional: a card file that swapped them would otherwise
-- decode into a requirement pointing the wrong way.
data RequireBlock = MkRequireBlock
  { duration :: Duration.Duration,
    -- | Named for a creature a ref picks at resolution (Lineprancers), Matching
    -- for CR 611.2c's class re-read at each declaration (Alluring Scent).
    blocker :: RestrictedCreatures.RestrictedCreatures ObjectRef.ObjectRef,
    -- | The attacker to be blocked. Nothing names none, "blocks this turn if
    -- able" (Predatory Rampage); Matching is a class CR 611.2c keeps live
    -- (Joraga Invocation).
    attacker :: Maybe (RestrictedCreatures.RestrictedCreatures ObjectRef.ObjectRef),
    -- | Parun.Types.BlockRequirement's `arity`: AnySubject is "must be blocked
    -- if able", one requirement per attacker that any one blocker obeys
    -- (Irresistible Prey).
    arity :: RequirementArity.RequirementArity
  }
  deriving (Eq, Ord, Show)
