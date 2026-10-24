module Parun.Types.AffectedUnless where

import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Quantity as Quantity

-- | Which creatures a combat restriction names, and CR 508.1c's "unless" gate.

-- Shared by CombatRestriction's CantAttack and CantBlock as expediency, not
-- because those two declare the same thing: they forbid different acts and
-- Parun.Engine.Combat reads each separately. The "alone" arms needed a field
-- these do not, so they got their own record (Parun.Types.AloneUnless) rather
-- than an optional field here.
data AffectedUnless = MkAffectedUnless
  { affected :: Affected.Affected,
    -- | Nothing is the unconditional restriction, which is most of them, so the
    -- key is elided rather than written null.
    unless :: Maybe Condition.Condition,
    -- | CR 116.2d: the name this face gives the ability stating the restriction,
    -- so that face's own SpecialAction.IgnoreThisUntilEndOfTurn can say WHICH
    -- effect a payment ignores -- "the effect from that ability", singular.
    -- Parun.Types.PlayerStaticAbility.name on the player axis, with the same
    -- meaning and joined to the grant by the same dataflow lint in
    -- Parun.AbilitySlotLintSpec.
    --
    -- Nothing for the overwhelming majority, which grant no such permission and
    -- so have nothing to be referred to by. Volrath's Curse's one sentence
    -- declares BOTH halves of "can't attack or block" under one name, which is
    -- what makes one payment cover both. A CR 613.1f
    -- Modification.LoseNamedAbility reads it too (Synthetic Grounded Sentry).
    name :: Maybe AbilityName.AbilityName,
    -- | CR 508.1c with CR 109.5: the number the affected set's EnclosingAmount
    -- operand compares against, read for the SOURCE -- Ensnaring Bridge's
    -- "power greater than the number of cards in your hand".
    -- Parun.Types.TargetSlot's `amount` on a restriction. Nothing for every
    -- restriction that compares against no computed number.
    amount :: Maybe Quantity.Quantity
  }
  deriving (Eq, Ord, Show)
