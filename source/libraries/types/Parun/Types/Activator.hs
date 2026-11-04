module Parun.Types.Activator where

import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 602.1b: which players an activated ability's own activation instructions
-- let activate it; CR 602.2's "unless the object specifically says otherwise".
--
-- A separate axis from Parun.Types.ActivationRestriction, CR 602.5's "activate
-- only ..." rider. They compose: Detention Vortex's "Only your opponents may
-- activate this ability and only as a sorcery" narrows both WHO and WHEN.
--
-- One reader, Parun.Engine.Game.activatorPermits, asked for the stack by
-- Parun.Engine.Activatable.mayActivateGiven and for CR 605.3b's routes by
-- Parun.Engine.Mana.routeAccess. Nothing here says who PAYS: CR 602.1a gives the
-- cost to the player activating the ability.
data Activator
  = -- | The players in this relation to CR 602.2's default activator, its `You`.
    Related PlayerRelation.PlayerRelation
  | -- | "Only this creature's owner may activate this ability" (CR 108.3).
    Owner
  deriving (Eq, Ord, Show)
