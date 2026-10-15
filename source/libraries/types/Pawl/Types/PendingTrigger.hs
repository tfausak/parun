module Pawl.Types.PendingTrigger where

import qualified Data.Map.Strict as Map
import Numeric.Natural (Natural)
import qualified Pawl.Types.AbilityName as AbilityName
import qualified Pawl.Types.Binding as Binding
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.GrantedAbility as GrantedAbility
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Timestamp as Timestamp
import qualified Pawl.Types.TriggerSource as TriggerSource
import qualified Pawl.Types.TriggeredAbility as TriggeredAbility

-- | CR 603.3: an ability that has TRIGGERED but is not yet on the stack. Gathered
-- by Pawl.Engine.Event (the rulebook-written ones by
-- Pawl.Engine.Event.Trigger.inherentTriggers) at the CR 117.5 boundary, ordered
-- and placed by Pawl.Engine.Engine.
--
-- `source` is what the ability hangs on -- the object it belongs to (CR 113.7),
-- or nothing at all for an inherent ability the rulebook rather than a card
-- states (CR 725.2, CR 702.179d). Both kinds
-- share this type so that CR 603.3b can order them as one batch;
-- `controller` is who controls the ability (CR 603.3a / CR 725.2). `bindings` is
-- the environment the trigger arrives with: what CR 603.7 captured when a
-- delayed ability was armed -- how "it" and "that card" (CR 603.7c) are
-- remembered, and how CR 725.2's crown steal remembers the damaging creature --
-- together with what Event.eventBindings read off the event itself (CR 603.6a's
-- entrant, under Binding.became). A delayed entry gets both, its captured
-- environment under the firing event's slots; an object's trigger has only the
-- second. Empty for a state trigger
-- (CR 603.8), which has no event to read; the SOURCE binding is stamped later
-- either way, by Engine.placeOne at placement.
data PendingTrigger = MkPendingTrigger
  { source :: TriggerSource.TriggerSource,
    controller :: PlayerId.PlayerId,
    ability :: TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card),
    bindings :: Map.Map SlotName.SlotName Binding.Binding,
    -- | CR 603.7a's creation moment, for a trigger that fired from a delayed
    -- entry, and Nothing for one an object simply has. Engine.placeBorne hands
    -- it to the stack object; TriggeredAbilitySource.createdAt says what reads
    -- it there.
    createdAt :: Maybe Timestamp.Timestamp,
    -- | CR 603.2's trigger event, as logged with its event group, and Nothing
    -- where the gatherer names none -- a state trigger (CR 603.8) and a
    -- reflexive one (CR 603.12), which have no event at all. Neither can be a
    -- mana ability, nor can an inherent ability, CR 605.1b's middle clause
    -- naming events an inherent ability the rulebook states never watches. Read
    -- by Pawl.Engine.ManaAbility.isTriggeredManaAbility, CR 605.5a asking what
    -- added the mana rather than only what the ability watches. The group is
    -- CR 610.3b's "after that ability triggered", which Engine.triggeredSince
    -- stamps on the stack object (GameState.stackedIn).
    firedBy :: Maybe LoggedEvent.LoggedEvent,
    -- | CR 113.2c: how many value-identical instances of `ability` the source
    -- bore as it triggered, 1 unless a printing or a grant repeats it. The
    -- allowance Pawl.Engine.Event.withinTriggerLimit gives a "triggers only
    -- once" rider, since the instances themselves are equal values.
    copies :: Natural,
    -- | CR 113.7a: the delayed abilities the source's rules text declared as
    -- this ability TRIGGERED (PC.delayedAbilities), which Engine.placeBorne
    -- hands to the stack object. Read as it triggered rather than at
    -- placement, so a copy effect the rest of the triggering resolution
    -- applies to the source does not change what its arms create. Empty for a
    -- sourceless ability.
    delayed :: Map.Map AbilityName.AbilityName (TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card))
  }
  deriving (Eq, Ord, Show)
