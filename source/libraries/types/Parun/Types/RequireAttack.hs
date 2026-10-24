module Parun.Types.RequireAttack where

import qualified Parun.Types.AttackTargetRef as AttackTargetRef
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures

-- | The payload of Parun.Types.Effect's RequireAttack arm: CR 508.1d's
-- requirement that the creatures named attack what the defender names, or
-- anything when it names nothing, for this duration. Alluring Siren's "target
-- creature an opponent controls attacks you this turn if able"; Gideon Jura's
-- "creatures that player controls attack Gideon Jura if able"; Courtly
-- Provocateur's "target creature attacks this turn if able".
--
-- The two sides are DIFFERENT types where Parun.Types.RequireBlock's are both
-- ObjectRefs, and that is CR 508.1b: what a creature attacks is a player, a
-- planeswalker or a battle, which Parun.Types.AttackTargetRef names. Named fields
-- all the same, so a card file reads as the sentence it transcribes.
data RequireAttack = MkRequireAttack
  { duration :: Duration.Duration,
    -- | Named for a creature a ref picks at resolution (Alluring Siren), Matching
    -- for CR 611.2c's class re-read at each declaration (Taunt).
    attacker :: RestrictedCreatures.RestrictedCreatures ObjectRef.ObjectRef,
    -- | Nothing names none, "attacks this turn if able" (Courtly Provocateur):
    -- any announcement CR 508.1b admits obeys it.
    defender :: Maybe AttackTargetRef.AttackTargetRef
  }
  deriving (Eq, Ord, Show)
