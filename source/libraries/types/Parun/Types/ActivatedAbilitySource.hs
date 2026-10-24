module Parun.Types.ActivatedAbilitySource where

import qualified Data.Map.Strict as Map
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.Card as Card
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.TriggeredAbility as TriggeredAbility

-- | CR 602: an activated ability on the stack -- the source permanent's id plus
-- the ability. The ability travels with the object so it resolves even if the
-- source leaves (CR 113.7a).
--
-- The id alone is enough once the source is gone: CR 400.7 mints a fresh id on
-- every zone change, so this one then names nothing, which is exactly the
-- trigger for CR 608.2h's last known information, filed under the same id in
-- GameState.lastKnown. Nothing about the source is copied in here; a snapshot
-- would have to be kept in step with a source that can still change while the
-- ability waits on the stack.
--
-- A record rather than two positional fields, so which of the two the id names
-- cannot be got wrong at a construction site and so the arm has the one payload
-- a codec needs. Parun.Types.Source is what this is an arm of.
data ActivatedAbilitySource = MkActivatedAbilitySource
  { source :: ObjectId.ObjectId,
    ability :: ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card),
    -- | CR 113.7a / 603.7: the delayed abilities the source's rules text
    -- declared as this object was put on the stack (PC.delayedAbilities),
    -- frozen with it: the ability exists independently of its source, so a copy
    -- effect or text change on the source afterwards does not change what its
    -- arms create.
    delayed :: Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)),
    -- | CR 607.5: the acquisition the ability came with on its source, frozen
    -- as it was put on the stack (CR 113.7a), so what it notes is linked to the
    -- pair it belongs to whatever the source becomes a copy of afterwards.
    acquisition :: Acquisition.Acquisition
  }
  deriving (Eq, Ord, Show)
