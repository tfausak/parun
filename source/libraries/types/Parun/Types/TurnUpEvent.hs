module Parun.Types.TurnUpEvent where

-- | CR 614.1a: an event that, about to happen to a face-down permanent, is
-- replaced by that permanent's being turned face up first and the event then
-- happening to the face-up permanent -- Illusionary Mask's "would assign or deal
-- damage, be dealt damage, or become tapped, instead it's turned face up and
-- ...".
--
-- Carried on Parun.Types.FaceDownState, the status the effect gave the
-- permanent, and minted into rows from there; see that type's
-- `turnsUpBefore`.
data TurnUpEvent
  = -- | CR 510.1: it would assign combat damage.
    AssignsCombatDamage
  | -- | CR 120.1: it would deal damage.
    DealsDamage
  | -- | CR 120.1: it would be dealt damage.
    IsDealtDamage
  | -- | CR 701.26a: it would become tapped.
    BecomesTapped
  deriving (Bounded, Enum, Eq, Ord, Show)
