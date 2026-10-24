module Parun.Types.CantAttackPlayer where

import Data.Set (Set)
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AttackTargetKind as AttackTargetKind
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.PlayerScope as PlayerScope

-- | CR 508.1c's PAIRWISE restriction: which creatures are restricted, whose side
-- of the board they may not attack, which of CR 506.3's attackable things on that
-- side are barred, and CR 508.1c's "unless" gate. Blazing Archon's "creatures
-- can't attack you" and Vow of Flight's "can't attack you or planeswalkers you
-- control".

-- Its own record rather than Parun.Types.AffectedUnless plus a field, for
-- Parun.Types.CantBeBlockedBy's reason: 'affected' names the creatures restricted
-- and 'defenders' names the players they may not be announced against, so the
-- two halves are not interchangeable and the second key is not a second
-- @affected@.
--
-- A Parun.Types.PlayerScope and not a Parun.Types.Filter over players, because CR
-- 109.5 is the whole of what the printed sentence needs: "you" is the source's
-- controller. Parun.Types.RequiredDefender says why the REQUIREMENT side could
-- not take this type -- Public Enemy's object is the enchanted creature's
-- controller, which is not CR 109.5's "you" -- and that asymmetry is why the two
-- axes carry different types rather than sharing one.
data CantAttackPlayer = MkCantAttackPlayer
  { affected :: Affected.Affected,
    defenders :: PlayerScope.PlayerScope,
    -- | CR 506.3: which announcements aimed at a player in 'defenders' are
    -- barred -- the seat itself, their planeswalkers, the battles they protect.
    -- Blazing Archon writes OfPlayer alone, Vow of Flight adds OfPlaneswalker;
    -- no card in data/cards writes OfBattle (Scryfall @o:/can't attack
    -- .*battles/@, 2026-09-01, no hit), so that arm is a regression fence rather
    -- than a proven behaviour. The empty set bars nothing, which the codec
    -- accepts as Parun.Codec.TypeLine accepts an empty required set.
    kinds :: Set AttackTargetKind.AttackTargetKind,
    -- | Nothing is the unconditional restriction. Elided rather than written
    -- null.
    unless :: Maybe Condition.Condition,
    -- | CR 116.2d: the name this face gives the ability stating the restriction,
    -- so that face's own SpecialAction.IgnoreThisUntilEndOfTurn can say WHICH
    -- effect a payment ignores -- "the effect from that ability", singular.
    -- Parun.Types.PlayerStaticAbility.name on the player axis, with the same
    -- meaning and joined to the grant by the same dataflow lint in
    -- Parun.AbilitySlotLintSpec.
    --
    -- Nothing for every printing, this arm included: CR 116.2d's producers that
    -- aim at an object state CantAttack and CantBlock instead. The field is here
    -- because whether a restriction can be NAMED is independent of its shape,
    -- which is why the "unless" gate beside it is on every arm too.
    name :: Maybe AbilityName.AbilityName
  }
  deriving (Eq, Ord, Show)
