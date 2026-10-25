module Parun.Types.PastActivation where

import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Card as Card
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 602.2: one activated ability a player began to activate this turn, kept
-- as the facts Parun.Types.CostModifier's criteria ask of an activation,
-- so "the FIRST activated ability you activate" (Professor Hojo) can be asked
-- of the turn's history whatever has happened to the objects since.
--
-- Every activation, mana abilities included (CR 605.1a): Tezzeret, Betrayer of
-- Flesh's ruling counts a mana ability as a first activation.
data PastActivation = MkPastActivation
  { -- | CR 602.2: the player who activated it.
    activator :: PlayerId.PlayerId,
    -- | The ability's source as the activation began.
    source :: ObjectSnapshot.ObjectSnapshot,
    -- | The ability activated, as announced; Nothing only for CR 305.6's
    -- intrinsic mana route, which is no printed ability. Its rule 702 keyword
    -- answers ActivationCriteria.grantedBy, and the ability itself
    -- Quantity.TimesThisTurn's Activated count (Dragon Whelp).
    ability :: Maybe (ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)),
    -- | CR 605.1a's side of the ability, for ActivationCriteria.whichKind.
    kind :: AbilityKind.AbilityKind,
    -- | CR 601.2c's object targets, as they stood when announced.
    targets :: [ObjectSnapshot.ObjectSnapshot]
  }
  deriving (Eq, Ord, Show)
