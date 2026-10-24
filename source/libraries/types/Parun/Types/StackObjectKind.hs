module Parun.Types.StackObjectKind where

-- | Which of CR 601.2c's announcement roads put an object on the stack: a spell
-- (CR 112.1), an activated ability (CR 113.3b), or a triggered ability (CR
-- 113.3c). The rule itself names only spells in its parenthetical, while CR
-- 602.2b and CR 603.3d route the two abilities through the same targeting step
-- -- so a card that says "the target of A SPELL" needs the limbs told apart, one
-- that says "an ACTIVATED ability" needs the two abilities told apart, and one
-- that says "a spell or ability" needs neither.
--
-- Recorded on Parun.Types.BecameTarget rather than re-derived, for that record's
-- `controller` reason: Parun.Engine.Event's matcher is pure over the condition,
-- the event, the bearer and CR 109.5's "you", with no GameState, and the
-- targeting object can leave the stack before anything reads the event.
--
-- Not a Bool, for Parun.Types.PayObligation's reason: @Spell@ says which limb of
-- the rule is in play where @True@ would say nothing. Three constructors and not
-- a spell\/ability pair plus a flag, for the same reason.
data StackObjectKind
  = -- | CR 112.1: "A spell is a card on the stack." Parun.Engine.Cast's
    -- announcement.
    Spell
  | -- | CR 113.3b's activated ability -- Parun.Engine.Activate's announcement.
    ActivatedAbility
  | -- | CR 113.3c's triggered ability -- Parun.Engine.Engine's announcement.
    TriggeredAbility
  deriving (Bounded, Enum, Eq, Ord, Show)
