-- What a trigger condition binds off the event it matched (CR 603.2, CR
-- 603.10): the slot map a matched trigger carries onto the stack, read from the
-- event alone with no game state. Split out of Parun.Engine.Event for size; it
-- sits below Parun.Engine.Event.Match and Parun.Engine.Event.Trigger.
module Parun.Engine.Event.Binding where

import Control.Applicative ((<|>))
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Numeric.Natural
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as ProjectionView
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.AbilityTriggered as AbilityTriggered
import qualified Parun.Types.AbilityWasActivated as AbilityWasActivated
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.AttackCount as AttackCount
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackTrigger as AttackTrigger
import qualified Parun.Types.AttackedSubject as AttackedSubject
import qualified Parun.Types.AttackedTrigger as AttackedTrigger
import qualified Parun.Types.AttackerBlocked as AttackerBlocked
import qualified Parun.Types.AttackerDeclared as AttackerDeclared
import qualified Parun.Types.AttackerUnblocked as AttackerUnblocked
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.BattlefieldCandidate as BattlefieldCandidate
import qualified Parun.Types.BecameAttached as BecameAttached
import qualified Parun.Types.BecameAttacked as BecameAttacked
import qualified Parun.Types.BecameBlocking as BecameBlocking
import qualified Parun.Types.BecameTarget as BecameTarget
import qualified Parun.Types.BecameUnattached as BecameUnattached
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.BecomesTargetedTrigger as BecomesTargetedTrigger
import Parun.Types.Binding (Binding)
import qualified Parun.Types.Binding as Binding.Type
import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.BlockTrigger as BlockTrigger
import qualified Parun.Types.BlocksDeclared as BlocksDeclared
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CausedBy as CausedBy
import qualified Parun.Types.Combat as Combat
import qualified Parun.Types.CounterChange as CounterChange
import qualified Parun.Types.CounterGrouping as CounterGrouping
import qualified Parun.Types.CounterHolder as CounterHolder
import qualified Parun.Types.CounterTrigger as CounterTrigger
import qualified Parun.Types.CountersPlaced as CountersPlaced
import qualified Parun.Types.CrewRole as CrewRole
import qualified Parun.Types.Crewing as Crewing
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePrevented as DamagePrevented
import qualified Parun.Types.DamageRecipient as DamageRecipient
import qualified Parun.Types.DamageTrigger as DamageTrigger
import qualified Parun.Types.DeclarationTrigger as DeclarationTrigger
import qualified Parun.Types.DiscardSubject as DiscardSubject
import qualified Parun.Types.DiscardTrigger as DiscardTrigger
import qualified Parun.Types.Discarded as Discarded
import qualified Parun.Types.Drew as Drew
import qualified Parun.Types.EntersTrigger as EntersTrigger
import qualified Parun.Types.Exploited as Exploited
import qualified Parun.Types.Filter as Filter.Type
import Parun.Types.GameEvent (GameEvent)
import qualified Parun.Types.GameEvent as GameEvent
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.LastKnown as LastKnown
import qualified Parun.Types.LeavesTrigger as LeavesTrigger
import qualified Parun.Types.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.Types.LeavingPermanent as LeavingPermanent
import qualified Parun.Types.LeftTheGame as LeftTheGame
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.ManaAbilityResolved as ManaAbilityResolved
import qualified Parun.Types.ManifestedDread as ManifestedDread
import qualified Parun.Types.Mentored as Mentored
import qualified Parun.Types.Moved as Moved
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PermanentIsDealtDamage as PermanentIsDealtDamage
import qualified Parun.Types.PermanentWasSacrificed as PermanentWasSacrificed
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.PlayerActed as PlayerActed
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Revealed as Revealed
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.SpellWasCopied as SpellWasCopied
import qualified Parun.Types.StepBegan as StepBegan
import qualified Parun.Types.StickerPut as StickerPut
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TappedForMana as TappedForMana
import qualified Parun.Types.TappedForManaTrigger as TappedForManaTrigger
import qualified Parun.Types.TappedPermanent as TappedPermanent
import Parun.Types.TriggerCondition (TriggerCondition)
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerSource as TriggerSource
import qualified Parun.Types.TurnedFaceUp as TurnedFaceUp
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange

-- CR 603.2: the bindings the EVENT contributes to a trigger it has just fired --
-- the environment in which the ability's "that player" / "that creature" is read.
-- Called only for a pair `matchesTrigger` already accepted, so an arm may assume
-- its condition's shape matched; a mismatched pair contributes nothing.
--
-- Separate from `matchesTrigger` rather than folded into a `Maybe bindings`
-- return, the two having different customers: a DELAYED ability matches several
-- events at once and carries the environment captured when it was armed (CR
-- 603.7c). A sourceless inherent ability (Event.Trigger.inherentTriggers)
-- gets the same call, with an id naming no object as its bearer.
--
-- THE SECOND AND THIRD ARGUMENTS ARE NOT READ OFF THE EVENT, and are the two
-- data here that are not. Both come off the same CR 117.5 batch, which
-- `eventTriggers` scans once and hands in; `delayedPending` has no batch scan of
-- its own and hands in Nothing and the empty map. Kept here rather than unioned
-- in at the call site so that eventBindingSlots below stays the single statement
-- of which slots a condition makes available, which is what the card lint reads.
--
-- The SECOND is CR 400.7f's "the new object that each Aura enchanting that
-- permanent became in its owner's graveyard", a fact about the BEARER's own zone
-- change, which the event that fired the trigger says nothing about.
--
-- The THIRD is the batch's whole battlefield-to-public-zone arrival table, keyed
-- by the id that departed. CR 603.10a's look-back is what makes it necessary: a
-- sacrifice is recorded BEFORE the move, so GameEvent.PermanentSacrificed names
-- the pre-move id and CR 400.7e's new object is nowhere on the event. The
-- PermanentSacrificed arm below is the one reader, and the reason it is a MAP
-- rather than a second Maybe is that the permanent the event names is not the
-- bearer -- Prowling Geistcatcher watches other creatures die.
--
-- THE FOURTH AND FIFTH ARGUMENTS are the bearer and CR 109.5 / 603.3a's "you",
-- the ability's controller -- matchesTriggerGiven's own second and third
-- arguments, and read the same way at both call sites (eventTriggers' `oid` and
-- `ctrl`, delayedPending's `DelayedTrigger.source` and
-- `DelayedTrigger.controller`). Most arms never read them; DamageToPlayerPrevented
-- below reads "you", to re-ask the condition's relation of a record a wider
-- shield stamped for more than one player (#3079), and a batch LeavesZone reads
-- both, to re-ask its subject of each card that left.
eventBindings :: GameState -> Maybe ObjectId -> Map.Map ObjectId ObjectId -> ObjectId -> PlayerId -> TriggerCondition -> GameEvent -> Map.Map SlotName.SlotName Binding
eventBindings = eventBindingsOver Map.empty

-- CR 122: the object a counter event names and how many counters moved, on or
-- off. Each record exists only where its count changed (GameEvent.CountersPut,
-- GameEvent.CountersRemoved), so the saturating difference is never 0.
countersMovedOn :: GameEvent -> Maybe (ObjectId, Numeric.Natural.Natural)
countersMovedOn event = case event of
  GameEvent.CountersPut placed -> Just (CountersPlaced.object placed, Natural.minusSaturating (CountersPlaced.after placed) (CountersPlaced.before placed))
  GameEvent.CountersRemoved change -> Just (CounterChange.object change, Natural.minusSaturating (CounterChange.before change) (CounterChange.after change))
  _ -> Nothing

-- `eventBindings` given the event's CR 603.10 sample (Event.Trigger.battlefieldAt),
-- the board matchesTriggerGiven read the same event against; empty answers
-- every id off the live board (`postEventView`).
eventBindingsOver :: Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> Maybe ObjectId -> Map.Map ObjectId ObjectId -> ObjectId -> PlayerId -> TriggerCondition -> GameEvent -> Map.Map SlotName.SlotName Binding
eventBindingsOver board gs bearerBecame becameInGraveyard bearer you cond event = case (cond, event) of
  -- CR 603.2b's "that player": the active player, on whose turn the step began.
  -- Shizuko, Caller of Autumn's "at the beginning of each player's upkeep, THAT
  -- PLAYER adds {G}{G}{G}" is the reader, and the seat it names is nobody the
  -- ability already has -- CR 109.5's "you" is Shizuko's controller, and CR
  -- 603.2b's step is each player's in turn.
  --
  -- Bound for EVERY TurnScope, not only EachTurn, which is what
  -- eventBindingSlots' unconditional promise for this condition needs. It names
  -- the seat the turn began with; under the shared team turns option an ability that
  -- reads the slot is re-bound once per player whose step it is (CR 805.4d,
  -- Parun.Engine.Event.Trigger.stepTriggerPlayers), and a delayed ability keeps
  -- the seat its arming environment named (Parun.Engine.Event.Trigger.delayedPending).
  --
  -- Unconditional given a match: every GameEvent.StepBegan carries a PlayerId,
  -- CR 500.1 giving every step exactly one turn to belong to.
  (TriggerCondition.StepBegins {}, GameEvent.StepBegan ev) ->
    Binding.setTriggerPlayer (StepBegan.player ev) Map.empty
  -- CR 603.2 / 120.1's damage, three slots unconditional given a match, since
  -- every GameEvent.DamageDealt carries a source and an amount:
  --
  -- HOW MUCH: Questing Beast's "that much" and Shroofus Sproutsire's "that many"
  -- count the damage the event carried, under the slot CR 615.13's prevention
  -- and CR 119.9's life gain stamp (Binding.eventAmount), summed by
  -- batchBindings across a batch. The AMOUNT the event recorded and never the
  -- damager's power: CR 702.19b lets a trampler assign part of its power to a
  -- blocker, so the two come apart on Parun.TriggerSpec's shroofusSpec board.
  --
  -- The DAMAGER, CR 120.1's source: Aragorn, Hornburg Hero's "it", read off the
  -- field matchesTrigger applied the actor to, and what `batchPartition` splits
  -- a batch by.
  --
  -- And where the trigger names one, the RECIPIENT: the damaged player under
  -- `triggerPlayer` for a player recipient (CR 702.70a's and Larceny's "that
  -- player", neither the bearer's controller nor the damager's), the damaged
  -- permanent under `became` for a permanent one (Bellowing Fiend's "that
  -- creature's controller", Hooded Blightfang's "that planeswalker"). Each is
  -- bound only for the kind of recipient the event names, and only where the
  -- trigger admits that kind, so a batch naming no recipient binds neither.
  (TriggerCondition.DealsDamage watched, GameEvent.DamageDealt ev) ->
    let target = DamageEvent.target ev
        (players, permanents) = namesRecipients watched
        player = if players then Recipient.playerOf target else Nothing
        permanent = if permanents then Recipient.objectOf target else Nothing
     in maybe id Binding.setTriggerPlayer player (maybe id Binding.setBecame permanent (Binding.setCombatDamager (DamageEvent.source ev) (Binding.setEventAmount (DamageEvent.amount ev) Map.empty)))
  -- CR 603.2's "that many" and the "that creature" Binding.became holds, no zone
  -- change: how many counters moved, read off the event's own before/after pair,
  -- and on what. Chandra,
  -- Fire Artisan's "she deals that much damage" counts the loyalty that came off,
  -- not the damage that caused it (CR 306.8's removal saturates), and one CR
  -- 510.2 batch is one record. Auntie Ool, Cursewretch reads the creature.
  --
  -- Unconditional given a match, which is what eventBindingSlots' promise needs:
  -- every counter event carries its object and both counts. The amount needs one
  -- permanent, the object one permanent the bearer does not name already
  -- (CR 113.7a's source slot does), so a batch stamps neither (CR 603.2c) and a
  -- Self holder no object.
  --
  -- A DEAD ID IS POSSIBLE and is the payload's problem, `became`'s standing
  -- posture: matchesTrigger admits the CR 704.5f victim a -1/-1 counter made
  -- through Projection.viewWithLastKnown.
  (TriggerCondition.CountersChange counterTrigger, _)
    | Just (oid, amount) <- countersMovedOn event ->
        let withObject = case (CounterTrigger.holder counterTrigger, CounterTrigger.grouping counterTrigger) of
              (CounterHolder.Permanent _, CounterGrouping.EachCounter) -> Binding.setBecame oid
              (CounterHolder.Permanent _, CounterGrouping.EachPermanent) -> Binding.setBecame oid
              _ -> id
            withAmount = case CounterTrigger.grouping counterTrigger of
              CounterGrouping.EachPermanent -> Binding.setEventAmount amount
              _ -> id
         in withObject (withAmount Map.empty)
  -- CR 603.2c's batch reading: the damagers' CONTROLLER, Norn's Decree's "that
  -- opponent", off the same `postEventView` the matcher read the Filter
  -- through, so "whose was it" and "did it qualify" come from one sample. And
  -- the DAMAGED PLAYER under `triggerPlayer`, Feline Sovereign's "that player
  -- controls". One seat each per member, and one each per trigger:
  -- `batchPartition` below is what splits the batch by both. No damaged player
  -- for "to one or more players" (Forth Eorlingas!), whose occurrence spans
  -- every player the step damaged, so `batchPartition` leaves it whole.
  --
  -- Unconditional given a match: that matcher answers False for a damager with
  -- no view or a recipient that is no player, and a permanent's view always
  -- carries its controller.
  --
  -- The sample is a regression fence here: no board in the suite changes a
  -- damager's controller between the damage and the scan.
  (TriggerCondition.PermanentsDealCombatDamageToPlayer p, GameEvent.DamageDealt ev) ->
    let damager = DamageEvent.source ev
        damaged = if PermanentsDealCombatDamageToPlayer.oneOrMorePlayers p then Nothing else Recipient.playerOf (DamageEvent.target ev)
     in maybe id Binding.setTriggerPlayer damaged (maybe id Binding.setDamagersController (Filter.controller =<< postEventView board gs damager) Map.empty)
  -- CR 725.2's "its controller becomes the monarch": the damaging creature,
  -- under the reserved trigger-source slot Effect.BecomeMonarch's
  -- ControllerOfSource reads. The abilities have no source (CR 725.2), and no
  -- card bears this condition, so Engine.placeBorne's restamp of that slot never
  -- meets it.
  (TriggerCondition.CreatureDealtCombatDamageToMonarch, GameEvent.DamageDealt ev) -> Binding.setTriggerSource (DamageEvent.source ev) Map.empty
  -- CR 726.2's "the controller of those creatures": the damager under the slot
  -- Effect.TakeTheInitiative's ControllerOfSource reads, the monarch arm's
  -- reason, and its controller off the event's sample, which `batchPartition`
  -- splits the batch by. batchBindings keeps the FIRST member's trigger source,
  -- so the first damaging creature stands for the occurrence.
  (TriggerCondition.CreaturesDealtCombatDamageToInitiative, GameEvent.DamageDealt ev) ->
    let damager = DamageEvent.source ev
     in maybe id Binding.setDamagersController (Filter.controller =<< postEventView board gs damager) (Binding.setTriggerSource damager Map.empty)
  -- CR 400.7e off the CARD rather than off the move: Planar Void's "exile that
  -- card" acts on the one arrival its trigger matched, so this binds
  -- ZoneChange.object alone where the two arms above bind every arrival as a
  -- group. That is what makes a melded permanent's two triggers exile a card
  -- each instead of both exiling both. putIntoZoneSlots says which triggers.
  (TriggerCondition.PutIntoZone t, GameEvent.Moved m)
    | bindsArrival t -> Binding.setBecame (ZoneChange.object (Moved.change m)) Map.empty
  (TriggerCondition.PutIntoZone t, GameEvent.CardArrived zc)
    | bindsArrival t -> Binding.setBecame (ZoneChange.object zc) Map.empty
  -- CR 603.6a: entersSlots' slots, off the entry matched.
  (TriggerCondition.Enters t, GameEvent.Moved (Moved.MkMoved zc _ _ _ _ _ _ _)) -> entersBindings gs t zc
  -- CR 708.7 through CR 603.2. A Matching subject binds Pine Walker's "that
  -- creature" (CR 603.2): the permanent that was turned face up, which it
  -- untaps. The bearer is a bystander here -- CR 113.7a's source slot names the
  -- WATCHER, and on Pine Walker's own board the two are different permanents --
  -- so the subject needs a name of its own.
  --
  -- THE SAME SLOT the zone-change arms above stamp, deliberately widened rather
  -- than a fresh one. Turning face up is NOT a zone change: CR 708.8 restores the
  -- permanent's copiable values and leaves it on the battlefield, so CR 400.7
  -- mints no new id and nothing here is an incarnation a card became. What carries
  -- the widening is that CR 400.7e's slot is the printed word "it"/"that
  -- creature" -- the thing the event names, which the ability's source is not --
  -- and Resolve, where the slot is read, never learns which condition placed the
  -- ability, so a second slot would be two names for one notion kept apart by
  -- every reader for a distinction no rule draws. It is also the only choice that
  -- serves CR 603.1b's AnyOf, whose slots eventBindingSlots INTERSECTS: a fresh
  -- name would make the intersection with Matching Enters empty forever, and
  -- Case of the Pilfered Proof reads exactly that intersection.
  --
  -- Unconditional given a match, which is what eventBindingSlots' per-condition
  -- promise needs: every GameEvent.TurnedFaceUp carries exactly one permanent.
  -- Bound whatever the Filter admitted, for entersSlots' reason.
  --
  -- A Self subject gets no such slot: there the subject IS the bearer, whom CR
  -- 113.7a's source slot already names.
  --
  -- Nor does the X chosen for the cost ride on a Matching subject: CR 702.37f
  -- and CR 702.168e give it to "other abilities of THAT PERMANENT", and a
  -- watcher is another permanent.
  --
  -- A Self subject binds CR 702.37f / 702.168e's X instead: "the value of X in
  -- those abilities is equal to the value of X chosen as the [morph / disguise]
  -- special action was taken", bound where the X a spell announced is bound, so
  -- the trigger's target count (Parun.Engine.Engine.placeBorne) and its effects
  -- read it alike. Off the event and never off the permanent, which state-based
  -- actions may already have taken away (Parun.Types.TurnedFaceUp). Nothing when
  -- no X was chosen.
  (TriggerCondition.TurnedFaceUp subject, GameEvent.TurnedFaceUp t) -> case subject of
    ActingPermanent.Self -> maybe Map.empty (\x -> Binding.fromChoices Map.empty (Just x) Seq.empty) (TurnedFaceUp.announcedX t)
    ActingPermanent.Matching _ -> Binding.setBecame (TurnedFaceUp.object t) Map.empty
  -- CR 123.3's "that creature": the object the sticker went on, which the event
  -- carries (Tusk and Whiskers). No zone change, so CR 400.7e's slot is the
  -- printed word, CountersChange's reason.
  (TriggerCondition.PlacesSticker _, GameEvent.StickerPut put) ->
    Binding.setBecame (StickerPut.object put) Map.empty
  -- "That player": the discarder, which CR 701.9a makes one player and the event
  -- carries directly. The same reserved slot CR 702.70a's poisonous uses, for the
  -- same reason -- a player the EVENT names, which CR 109.5's `you` cannot stand
  -- in for. "That card" is CR 400.7e's `became`, the card's new incarnation the
  -- event carries (Bag of Holding's "exile that card from your graveyard").
  --
  -- CR 603.2c's batch reading instead counts "that much" (Magmakin
  -- Artillerist): one card per Discarded event, summed across the group by
  -- batchBindings. A Self discard stamps nothing: its card is the bearer, whom
  -- CR 113.7a's source slot already names, and its discarder is the owner CR
  -- 113.8 and CR 108.4a make the controller, whom Binding.setYou names.
  (TriggerCondition.Discards trigger, GameEvent.Discarded (Discarded.MkDiscarded discarder card _ _ _)) -> case (DiscardTrigger.subject trigger, DiscardTrigger.batching trigger) of
    (_, Batching.OneOrMore) -> Binding.setEventAmount 1 Map.empty
    (DiscardSubject.Discarder _, Batching.EachOccurrence) -> Binding.setBecame card (Binding.setTriggerPlayer discarder Map.empty)
    (DiscardSubject.Self, Batching.EachOccurrence) -> Map.empty
  -- The drawing player, a discarder's player slot for CR 121.1's draw (Underworld
  -- Dreams' "that player").
  (TriggerCondition.PlayerDrawsNthCard _, GameEvent.Drew (Drew.MkDrew drawer _)) ->
    Binding.setTriggerPlayer drawer Map.empty
  -- CR 607.2h's "that card": the card the linked static revealed (God-Eternal
  -- Kefnet's "copy that card").
  (TriggerCondition.RevealedThisWay _, GameEvent.Revealed revealed) ->
    Map.singleton Binding.revealedCard (Binding.toObject (Revealed.card revealed))
  -- CR 701.62a's "a card you put into your graveyard this way" (Paranormal
  -- Analyst): the graveyard incarnations the event carries, under CR 400.7e's
  -- `became` -- one as the single binding, several (a CR 701.40f refusal sends
  -- both looked-at cards) as a group, and none binding nothing.
  (TriggerCondition.PlayerManifestsDread _, GameEvent.ManifestedDread ev) -> case ManifestedDread.cards ev of
    Seq.Empty -> Map.empty
    only Seq.:<| Seq.Empty -> Binding.setBecame only Map.empty
    every -> Binding.setBecameGroup every Map.empty
  -- CR 508.3: attackSlots' slots, off the event each arity matches.
  (TriggerCondition.Attacks t, _) -> attackBindings gs bearer you t event
  -- CR 603.6c: leavesSlots' slots, off the departure matched.
  (TriggerCondition.Leaves t, _) -> leavesBindings gs bearerBecame t event
  -- CR 615.13's "that many": how much this prevention effect prevented, which is
  -- the whole reason the event carries a number. The first reserved slot holding
  -- an AMOUNT rather than a reference, read back by Quantity.InSlot off the stack
  -- object these bindings are stamped on (see Binding.eventAmount).
  --
  -- The PLAYER share of the record, not the whole of it: one application can
  -- cover a player and their permanents at once (Divine Deflection), and the
  -- printed sentence this condition spells says "damage that would be dealt to
  -- you", so what was stopped on the way to a permanent is no part of "that
  -- many".
  --
  -- RE-ASKED against the relation, exactly as matchesTrigger's own arm asks it
  -- (CR 109.5): a shield admitting more than one player (Synthetic Impartial
  -- Ward's "any player") stamps every one of their entries into one
  -- DamagePrevented record, and only the share addressed to a player THIS
  -- relation admits is "that much" -- a wider shield's other recipients are no
  -- part of it. `you` is the ability's controller, threaded in from the two
  -- call sites below exactly as matchesTriggerGiven already receives it.
  --
  -- The recipient is NOT bound alongside it. Every payload this CONDITION
  -- carries acts on the ability's own source (Selfless Squire counters itself),
  -- and the player the recipient names here is CR 109.5's "you", already bound.
  (TriggerCondition.DamageToPlayerPrevented relation, GameEvent.DamagePrevented prevented) ->
    Binding.setEventAmount
      ( sum
          ( Map.filterWithKey
              (\recipient _ -> maybe False (PlayerRelation.holds (Game.teams gs) relation you) (Recipient.playerOf recipient))
              (Map.unionsWith (+) (DamagePrevented.amounts prevented))
          )
      )
      Map.empty
  -- CR 615.13's "that much" once more, off the same event and into the same
  -- reserved slot: the Vindicator deals what its own prevention stopped. The
  -- WHOLE record here where the arm above takes the player share, this condition
  -- being scoped to the applying instance rather than to a recipient.
  --
  -- The recipient is not bound alongside it for the arm above's reason -- the payload
  -- acts on a target it chooses, never on whoever the prevented damage was
  -- addressed to.
  --
  -- CR 120.1's SOURCES are, and they are the one thing this condition's payload
  -- can name that the arm above's cannot: New Way Forward's "that source's
  -- controller" points at the object that would have dealt the damage. EVERY
  -- source the condition's Filter admits is bound, together, and the amount is
  -- theirs: CR 615.13 fires once for one application however many sources it
  -- covered, so Judgment of Alexander's "that creature" over two prevented
  -- attackers names both, and a source the Filter refuses -- a noncreature one
  -- there -- is no part of either. Re-asked against the Filter here exactly as
  -- the match arm asks it (admittedPreventedSources). Not bound on the
  -- DamageToPlayerPrevented arm, whose printed sentences all speak about the
  -- recipient's side; a printing there that named the source would want the
  -- same stamp.
  (TriggerCondition.SelfPreventsDamage f, GameEvent.DamagePrevented prevented) ->
    let admitted = admittedPreventedSources (Projection.sourceContext gs (Just you) bearer) gs f prevented
     in Binding.setPreventedDamageSources (Map.keysSet admitted) (Binding.setEventAmount (sum (fmap sum admitted)) Map.empty)
  -- CR 603.2's "that much" and "that player": the amount the change recorded,
  -- never a life total (Sanguine Bond, Exquisite Blood), and the player whose
  -- life changed (False Cure, Mindcrank). Bound whichever relation matched, since
  -- eventBindingSlots promises per condition; under You the player slot is a
  -- second name for CR 109.5's "you". A batch binds neither (eventBindingSlots).
  (TriggerCondition.LifeChanges lifeTrigger, _)
    | LifeTrigger.batching lifeTrigger == Batching.EachOccurrence,
      Just (pid, amount) <- Game.lifeChangeOf (LifeTrigger.direction lifeTrigger) event ->
        Binding.setTriggerPlayer pid (Binding.setEventAmount amount Map.empty)
  -- CR 601.2i's "it": the spell that became cast, which the event names and
  -- which nothing else on the ability does. Presence of the Master's "whenever a
  -- player casts an enchantment spell, counter it" is the reader.
  --
  -- The STACK object, not a card in a hand or a library -- see GameEvent.SpellCast
  -- for why the two are different objects and why this is the one the rule is
  -- about. Guaranteed to be a real id when the binding is made: CR 601.2a leaves
  -- the spell on the stack "until it resolves, it's countered, or a rule or
  -- effect moves it elsewhere", and none of those can have happened before the
  -- gather, the cast being the last thing Parun.Engine.Cast does. By RESOLUTION
  -- it can be gone -- the case CR 608.2h is about -- which is the payload's
  -- business rather than this function's: CR 701.6a's funnel no-ops on a dead id.
  --
  -- The CASTER alongside it, under the reserved slot CR 701.9a's discard trigger
  -- and CR 702.70a's poisonous already stamp: Kambal, Consul of Allocation's
  -- "that player loses 2 life" is the reader, and CR 112.2 makes that player the
  -- spell's controller -- "by default, the player who put it on the stack".
  --
  -- A SLOT rather than a reader that derives the controller from the bound
  -- spell, and CR 608.2h is the argument: the spell can be GONE by the time this
  -- ability resolves (another trigger counters it first), and a derivation would
  -- then have to fall back to last known information for a fact the event
  -- carried outright. The LifeChanges arm binds both halves of its event for
  -- the same reason.
  --
  -- Bound whatever the Filter admitted, which is what eventBindingSlots'
  -- per-condition promise needs -- that function answers with no event and no
  -- Filter in hand, so a slot it names has to hold for every cast the condition
  -- can match. Both do: GameEvent.SpellCast carries an ObjectId and a PlayerId
  -- unconditionally, so no shape of the event withholds either.
  --
  -- A Self subject binds nothing (eventBindingSlots' arm says why), so it falls
  -- to the fallthrough.
  (TriggerCondition.SpellCast (SpellCast.MkSpellCast (ActingPermanent.Matching _) _ _ _ _ _), GameEvent.SpellCast (SpellWasCast.MkSpellWasCast caster spell _ _ _ _)) ->
    Binding.setTriggerPlayer caster (Binding.setCastSpell spell Map.empty)
  -- Magecraft's "or copy" binds the same pair off its own event (CR 707.10):
  -- the copy, and the player who copied it.
  (TriggerCondition.SpellCast (SpellCast.MkSpellCast (ActingPermanent.Matching _) _ _ _ _ _), GameEvent.SpellCopied (SpellWasCopied.MkSpellWasCopied copier copy)) ->
    Binding.setTriggerPlayer copier (Binding.setCastSpell copy Map.empty)
  -- CR 602.2b's "that ability" and "that player": the ability on the stack and
  -- its activator (CR 602.2a). Unconditional given a match.
  (TriggerCondition.AbilityActivated _, GameEvent.AbilityActivated activated) ->
    Binding.setTriggerPlayer (AbilityWasActivated.player activated) (Binding.setActivatedAbility (AbilityWasActivated.ability activated) Map.empty)
  -- CR 603.2's "that player": the player who acted, Ob Nixilis, Unshackled's
  -- searcher. Unconditional given a match.
  (TriggerCondition.PlayerActs _, GameEvent.PlayerActed acted) ->
    Binding.setTriggerPlayer (PlayerActed.player acted) Map.empty
  -- CR 601.2c / 603.2c: becomesTargetedSlots' slots, off the announcement
  -- matched.
  (TriggerCondition.BecomesTargeted c, GameEvent.BecameTarget t) -> becomesTargetedBindings c t
  -- The same slot off the same field, one recipient over: Amulet of Safekeeping's
  -- "counter THAT SPELL OR ABILITY unless its controller pays {1}" names the
  -- object that did the targeting, and here the targeted party is a player rather
  -- than the bearer, so nothing else on the ability reaches it.
  --
  -- Unconditional in the same sense as a Self BecomesTargeted's
  -- (becomesTargetedSlots), and its controller likewise takes no slot of its
  -- own: Resolve.payerOf reads this slot as "whoever controls that object",
  -- which is CR 405.4's answer to "its controller".
  (TriggerCondition.ControllerBecomesTarget {}, GameEvent.BecameTarget t) ->
    Binding.setTargetingObject (BecameTarget.source t) Map.empty
  -- CR 509.3a / 509.3e on the blocking side: Super-Soldier Serum's "it" is the
  -- blocker. The attackers ride the event but go unbound: no printing names them.
  --
  -- The pairwise count reads the other event, so it stamps nothing here, which
  -- keeps a pairwise branch of CR 603.1b's AnyOf from naming its own blocker.
  (TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger BlockRole.Blocker _ count), GameEvent.BlocksDeclared (BlocksDeclared.MkBlocksDeclared blocker _)) -> case count of
    BlockCount.Once -> Binding.setBlockingCreature blocker Map.empty
    BlockCount.AtLeast {} -> Binding.setBlockingCreature blocker Map.empty
    BlockCount.EachCreature _ -> Map.empty
  -- CR 509.3b's "that creature": the ATTACKER on the very same declaration, which
  -- Loyal Sentry's payload destroys. CR 509.3d's "that creature": the blocker,
  -- which rule 702.25a's payload gives -1/-1 and CR 701.54c's sacrifices. The
  -- named creature gets no slot of its own: the bearer is CR 113.7a's source,
  -- and a bystander's rule names it only in the condition.
  --
  -- Guarded on the named end, so where the Filter admits the OTHER end this
  -- stamps nothing: under CR 603.1b's AnyOf the two roles are unioned off one
  -- event, and Thicket Basilisk's "that creature" would otherwise name the
  -- Basilisk itself
  -- (data/scenarios/thicket-basilisk-destroys-a-non-wall-at-end-of-combat.json),
  -- Venom's "the other creature" its host. Read outside CR 603.7c's frame, so a
  -- delayed trigger's slot atom in the Filter would stamp nothing; none in
  -- data/cards, 2026-11-03.
  (TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger role creature (BlockCount.EachCreature _)), GameEvent.BecameBlocking (BecameBlocking.MkBecameBlocking {BecameBlocking.attacker = attacker, BecameBlocking.blocker = blocker})) -> case role of
    BlockRole.Blocker
      | admittedAt (Projection.sourceContext gs (Just you) bearer) board gs blocker creature -> Binding.setBlockedCreature attacker Map.empty
    BlockRole.Attacker
      | admittedAt (Projection.sourceContext gs (Just you) bearer) board gs attacker creature -> Binding.setBlockingCreature blocker Map.empty
    _ -> Map.empty
  -- CR 509.3c: the blocked attacker is Somberwald Alpha's "it", and CR 702.130a's
  -- "defending player" (afflict) is CR 508.5's, which every writer of the event
  -- stamps -- Combat.declareBlockers, Combat.becomeBlocked (CR 509.1h's effect)
  -- and Combat.putOntoBattlefieldBlocking (CR 509.4).
  (TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger BlockRole.Attacker _ BlockCount.Once), GameEvent.AttackerBlocked (AttackerBlocked.MkAttackerBlocked attacker defending _)) ->
    Binding.setTriggerPlayer defending (Binding.setAttackingCreature attacker Map.empty)
  -- CR 509.3e's "that attacking creature" (Seifer, Balamb Rival), off both of
  -- that form's events: the becoming and an arrival at an attacker blocked
  -- already. Without the second the trigger fires with an empty binding map,
  -- which is why Parun.ZoneTriggerSpec's representativeEvents lists BOTH. The
  -- defending player goes unbound, since the arrival does not carry one.
  (TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger BlockRole.Attacker _ (BlockCount.AtLeast _ _)), GameEvent.AttackerBlocked (AttackerBlocked.MkAttackerBlocked attacker _ _)) ->
    Binding.setAttackingCreature attacker Map.empty
  (TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger BlockRole.Attacker _ (BlockCount.AtLeast _ _)), GameEvent.BecameBlocking (BecameBlocking.MkBecameBlocking {BecameBlocking.attacker = attacker})) ->
    Binding.setAttackingCreature attacker Map.empty
  -- CR 701.3a's "that creature" read from the ATTACHMENT: the host the bearer
  -- went onto, which Enormous Energy Blade taps. SelfBecomesAttachedBy has no arm
  -- here at all, and the two together are the pair -- whichever end of rule
  -- 701.3a's event is not the bearer is the one that earns a name.
  --
  -- Guaranteed given a match rather than conditional, which is what
  -- eventBindingSlots' per-condition promise needs: matchesTrigger has already
  -- declined every event whose host is a player, so Recipient.objectOf answers
  -- Just for every event that reaches here and the Map.empty branch is dead.
  (TriggerCondition.SelfBecomesAttachedTo _, GameEvent.BecameAttached (BecameAttached.MkBecameAttached {BecameAttached.host = host})) ->
    maybe Map.empty (`Binding.setAttachedHost` Map.empty) (Recipient.objectOf host)
  -- CR 701.3d's "that permanent": the host the bearer came OFF, which Grafted
  -- Wargear sacrifices. The arm above's mirror off the other event, guaranteed
  -- for the same reason.
  (TriggerCondition.SelfBecomesUnattachedFrom _, GameEvent.BecameUnattached (BecameUnattached.MkBecameUnattached {BecameUnattached.host = host})) ->
    maybe Map.empty (`Binding.setUnattachedHost` Map.empty) (Recipient.objectOf host)
  -- CR 702.134c's "that creature": the creature that was mentored, the event's
  -- second id -- Aegis of the Legion's shield counter goes on it. The MENTOR gets no
  -- slot: matchesTrigger has just proved it is the bearer's host, and no printed
  -- payload points at it.
  --
  -- Unconditional given a match, which is what eventBindingSlots' per-condition
  -- promise needs: every GameEvent.Mentored carries both ids.
  (TriggerCondition.AttachedCreatureMentors, GameEvent.Mentored (Mentored.MkMentored _ mentored)) ->
    Binding.setMentoredCreature mentored Map.empty
  -- CR 702.110b's "a creature": the creature that was exploited, the event's
  -- second id -- Profaner of the Dead's "the exploited creature's toughness"
  -- and Henry Wu, InGen Geneticist's "the exploited creature" read it. The
  -- EXPLOITER gets no slot: under Self, matchesTrigger has just proved it is
  -- the bearer, which Binding.triggerSource already answers, and under Matching
  -- no printed payload names it.
  --
  -- Unconditional given a match, which is what eventBindingSlots' per-condition
  -- promise needs: every GameEvent.Exploited carries both ids.
  (TriggerCondition.Exploits {}, GameEvent.Exploited (Exploited.MkExploited _ exploited)) ->
    Binding.setExploitedCreature exploited Map.empty
  -- CR 702.122b's "that Vehicle": the Vehicle the bearer just crewed, which
  -- Gearshift Ace's "that Vehicle gains first strike until end of turn" reads.
  -- The CREWERS get no slot -- matchesTrigger has just proved the bearer is one
  -- of them, and no printed payload points at the others.
  --
  -- Unconditional given a match, which is what eventBindingSlots' per-condition
  -- promise needs: every GameEvent.Crewed carries a vehicle.
  (TriggerCondition.Crews CrewRole.Crewer, GameEvent.Crewed ev) ->
    Binding.setCrewedVehicle (Crewing.vehicle ev) Map.empty
  -- CR 702.122e's rider: the creatures that paid THAT activation's crew cost,
  -- which Mighty Servant of Leuk-o's intervening "if" counts. The event the
  -- rider is about is the one being matched, so taking the set off it is what
  -- makes "only creatures that were tapped to pay the cost of the crew ability
  -- that caused it to trigger" true of a Vehicle crewed twice in a turn. The
  -- VEHICLE gets no slot: it is the bearer, and Binding.triggerSource already
  -- names it.
  --
  -- Unconditional given a match, which is what eventBindingSlots' per-condition
  -- promise needs: every GameEvent.BecameCrewed carries the set, empty where the
  -- cost had no TapForTotalPower component. An empty set still binds, and the
  -- count reads 0 -- which is the rider's own answer, not an absent slot.
  (TriggerCondition.Crews (CrewRole.Vehicle _), GameEvent.BecameCrewed ev) ->
    Binding.setCrewers (Crewing.crewedBy ev) Map.empty
  -- CR 701.26a's permanent, bound because the attachment link is NOT enough:
  -- Blight's "destroy it" names the land that became tapped, which the Aura
  -- leaving the battlefield before its trigger resolves does not change.
  --
  -- Gated on the watched direction, so under CR 603.1b's AnyOf the other
  -- direction's event falls through and stamps nothing. Mesmeric Orb's "that
  -- permanent's controller" reads the untap direction's slot.
  --
  -- A OneOrMore batch binds nothing, falling to the arm below: Deeproot
  -- Pilgrimage's payload names no tapped permanent, and one slot could not
  -- name a batch of them.
  (TriggerCondition.BecomesTapState watched, GameEvent.BecameTapped tapped)
    | BecomesTapState.batching watched == Batching.EachOccurrence && BecomesTapState.status watched == TapState.Tapped ->
        Binding.setTapStatePermanent TapState.Tapped tapped Map.empty
  (TriggerCondition.BecomesTapState watched, GameEvent.BecameUntapped untapped)
    | BecomesTapState.batching watched == Batching.EachOccurrence && BecomesTapState.status watched == TapState.Untapped ->
        Binding.setTapStatePermanent TapState.Untapped untapped Map.empty
  -- CR 106.12a's permanent, bound for the BecomesTapState arm's reason: Wild
  -- Growth's "its controller" is the enchanted land's controller, and
  -- PlayerRef.HolderOfBound is how a card names it -- CR 109.5's "you" would
  -- answer the Aura's controller instead, which an Aura on an opponent's
  -- land makes a different seat.
  --
  -- Unconditional given a match, an Attached Leaves' claim and for its
  -- reason: matchesTrigger accepts only a GameEvent.TappedForMana whose
  -- permanent IS the bearer's host, so the id is always there.
  (TriggerCondition.TappedForMana (TappedForManaTrigger.MkTappedForManaTrigger TappedPermanent.Attached _ _), GameEvent.TappedForMana tapped) ->
    Binding.setManaSource (TappedForMana.permanent tapped) Map.empty
  -- The same slot for the bystander reading: Vernal Bloom's "its controller"
  -- reads it through PlayerRef.HolderOfBound. "That player" is the tapping
  -- player instead (Manabarbs, Mana Flare), who differs where an effect lets
  -- another player tap it (Piracy).
  --
  -- Unconditional given a match, the arm above's reason: matchesTrigger accepts
  -- only a GameEvent.TappedForMana, which carries the permanent and the player
  -- outright.
  (TriggerCondition.TappedForMana (TappedForManaTrigger.MkTappedForManaTrigger (TappedPermanent.Matching _) _ _), GameEvent.TappedForMana tapped) ->
    Binding.setTriggerPlayer (TappedForMana.player tapped) (Binding.setManaSource (TappedForMana.permanent tapped) Map.empty)
  -- CR 605.1b's resolution read off the bearer's own mana ability: the permanent
  -- needs no slot -- it IS the bearer, whom Binding.triggerSource already names
  -- -- and what the payload reads instead is how much mana the activation made,
  -- which Tyvar the Bellicose's "equal to the amount of mana this creature
  -- produced" takes through Quantity.InSlot.
  --
  -- Unconditional given a match, an Attached TappedForMana's claim and for
  -- its reason: matchesTrigger accepts only a GameEvent.ManaAbilityResolved
  -- whose permanent IS the bearer, and the amount is on the event outright.
  (TriggerCondition.SelfManaAbilityResolves, GameEvent.ManaAbilityResolved resolved) ->
    Binding.setEventAmount (ManaAbilityResolved.amount resolved) Map.empty
  -- CR 725.1's newly crowned player: Garland, Royal Kidnapper's "that player",
  -- whose creature the trigger then targets and whose crown its duration watches.
  -- Bound whichever relation matched, for the reason the LifeChanges arm
  -- gives: eventBindingSlots answers per CONDITION with no relation in hand, so
  -- the slot has to hold for every relation this condition admits. Under You the
  -- crowned player is also CR 109.5's "you", which is a redundancy rather than a
  -- wrong answer.
  --
  -- Unconditional given a match: GameEvent.BecameMonarch carries a PlayerId
  -- outright, and CR 725.3 makes it exactly one.
  (TriggerCondition.PlayerBecomesMonarch _, GameEvent.BecameMonarch crowned) ->
    Binding.setTriggerPlayer crowned Map.empty
  -- CR 701.21a's sacrificing player: Vengeful Tracker's "this creature deals 2
  -- damage to THEM", a seat CR 109.5's "you" is not -- the condition's Opponent
  -- relation is what makes the two come apart.
  --
  -- Bound whichever relation matched, the PlayerBecomesMonarch arm's reason:
  -- eventBindingSlots answers per CONDITION with no relation in hand, so the slot
  -- has to hold for every relation this condition admits, and under You it is a
  -- redundant second name rather than a wrong one.
  --
  -- Unconditional given a match: GameEvent.PermanentSacrificed carries a PlayerId
  -- outright, CR 701.21a's sacrifice having exactly one performer.
  --
  -- CR 400.7e's new object BESIDE it -- the card Prowling Geistcatcher's "exile
  -- it" has to move -- and it is the reason this arm is
  -- handed the batch's arrival table at all: CR 603.10a records the sacrifice
  -- BEFORE the move (Event.sacrificeIn), so the id the event carries is the
  -- battlefield permanent CR 400.7 went on to delete and nothing on the event
  -- names what it became. `becameInGraveyard` is keyed by exactly that departed
  -- id.
  --
  -- In whichever public zone it reached: a CR 614.1 replacement sending it to
  -- exile (Rest in Peace) leaves the sacrifice recorded, and CR 400.7e's "the
  -- zone it moved to" is the exile, proved by Parun.TriggerSpec's "CR 400.7e a
  -- sacrifice redirected to exile is found there".
  --
  -- CONDITIONAL, so the slot is claimed by eventBindingSlotsSometimes rather than
  -- by the floor: a replacement can send the permanent to a HIDDEN zone (a
  -- library), which leaves the table without the row, and delayedPending scans
  -- no batch at all. A payload that then finds nothing is what CR 400.7e
  -- prescribes rather than the silent no-op the card lint exists to catch.
  --
  -- The BEARER's own arrival is not consulted, unlike an Attached Leaves': this is a bystander condition and the permanent the event names is
  -- somebody else's -- Prowling Geistcatcher's "another creature".
  --
  -- CR 603.10a's departed permanent BESIDE both, a bystander Leaves' second
  -- slot for leavesSlots' reason: one printed "it" is two objects, and which one a
  -- card means is the card's business. Prowling Geistcatcher's "if that creature
  -- was a token" is about the permanent as it last existed on the battlefield --
  -- CR 111.7 has since made the token cease to exist -- while its "exile it" is
  -- about the graveyard card. Unconditional, unlike the arrival above:
  -- GameEvent.PermanentSacrificed carries the pre-move id outright, so no shape
  -- of the event withholds it.
  (TriggerCondition.PermanentSacrificed {}, GameEvent.PermanentSacrificed ev) ->
    let arrival = case Map.lookup (PermanentWasSacrificed.permanent ev) becameInGraveyard of
          Nothing -> Map.empty
          Just arrived -> Binding.setBecame arrived Map.empty
     in Binding.setDepartedPermanent (PermanentWasSacrificed.permanent ev) $
          Binding.setTriggerPlayer (PermanentWasSacrificed.player ev) arrival
  -- CR 603.3b's second class, read for that Saga and that player:
  -- GameEvent.AbilityTriggered names the object the chapter ability hangs on
  -- (CR 113.7) and the player who controls it (CR 603.3a), and the watcher is
  -- neither of them. data/cards/synthetic-chronicle-warden.json reads both, and
  -- its Opponent relation is what makes the seat something CR 109.5's "you" is
  -- not.
  --
  -- The Saga under CR 400.7e's slot rather than one of its own, which is a
  -- Matching TurnedFaceUp's case above and settled there: one permanent, one
  -- id, two unrelated objects, and Parun.Engine.Resolve never learns which condition
  -- placed the ability whose slot it is reading, so a second slot would have to
  -- be kept apart by every reader for a distinction no rule draws.
  --
  -- Both unconditional given a match, which is what eventBindingSlots'
  -- per-condition promise needs: matchesTrigger's arm rejects
  -- TriggerSource.Sourceless outright -- CR 725.2's and CR 702.179d's abilities
  -- hang on no Saga -- so every record it accepts carries an ObjectId, and every
  -- record carries a controller.
  (TriggerCondition.SagaFinalChapterTriggers _, GameEvent.AbilityTriggered record) ->
    case AbilityTriggered.source record of
      TriggerSource.Sourceless -> Map.empty
      TriggerSource.OfObject saga -> Binding.setBecame saga (Binding.setTriggerPlayer (AbilityTriggered.controller record) Map.empty)
  -- CR 120.3's "that much", read by the damage's RECIPIENT: Coalhauler Swine's
  -- "whenever this creature is dealt damage, it deals that much damage to each
  -- player". The same reserved slot CR 615.13's prevention and CR 119.9's life
  -- gain stamp (see Binding.eventAmount), and the same reading -- the AMOUNT the
  -- event recorded, never the damager's power or the bearer's: CR 702.19b lets a
  -- trampler split its power across a blocker and a player, and CR 120.2b admits
  -- noncombat damage whose amount its source's power never named at all.
  --
  -- ONE event's amount, which batchBindings sums under Batching.OneOrMore: two
  -- blockers' simultaneous damage (CR 510.2) is one trigger reading the total.
  -- data/scenarios/life-trigger/cr-603-2c-coalhauler-swine-reads-a-double-blocks-total-once.json
  -- proves the sum.
  --
  -- Unconditional given a match, which is what eventBindingSlots' per-condition
  -- promise needs: every GameEvent.DamageDealt carries a DamageEvent.amount,
  -- whichever of CR 120.2's damage kinds it is.
  --
  -- Under Batching.EachOccurrence the DAMAGER takes Binding.combatDamager
  -- beside it, which is CR 120.1's "an object that deals damage is the source
  -- of that damage" -- Belltower Sphinx's "that source's controller mills that
  -- many cards", read through PlayerRef.HolderOfBound. Also unconditional given
  -- a match: DamageEvent.source is an ObjectId outright, so there is nothing to
  -- fail. Not under OneOrMore, whose batch may name several sources.
  --
  -- The slot is not combat-scoped here even though its name is: CR 120.1 makes
  -- every damage event name a source, and Belltower Sphinx's trigger admits a
  -- Prodigal Sorcerer's ping as readily as a blocker's. Pinned by
  -- Parun.TriggerSpec's noncombat board.
  --
  -- The RECIPIENT under `became`, the object the event names: Death Pits of
  -- Rath's "destroy it". For a Self reading it is the bearer again. Also
  -- unconditional given a match, which admits only an object recipient.
  (TriggerCondition.IsDealtDamage watched, GameEvent.DamageDealt ev) ->
    let damager = case PermanentIsDealtDamage.batching watched of
          Batching.EachOccurrence -> Binding.setCombatDamager (DamageEvent.source ev)
          Batching.OneOrMore -> id
     in maybe id Binding.setBecame (Recipient.objectOf (DamageEvent.target ev)) (damager (Binding.setEventAmount (DamageEvent.amount ev) Map.empty))
  -- CR 120.3's "that many" for a damaged player (Lich), summed across the
  -- batch by batchBindings, and the damaged player under `triggerPlayer`, which
  -- batchPartition splits the batch by. A damaged planeswalker (Vengeful
  -- Pharaoh's) goes under `became` instead, the key batchPartition splits it
  -- off by: it names no player for "that player" to read.
  (TriggerCondition.PlayerIsDealtDamage _, GameEvent.DamageDealt ev) ->
    maybe id Binding.setTriggerPlayer (Recipient.playerOf (DamageEvent.target ev)) (maybe id Binding.setBecame (Recipient.objectOf (DamageEvent.target ev)) (Binding.setEventAmount (DamageEvent.amount ev) Map.empty))
  -- CR 603.2c's "that many" (Rakshasa Vizier): THIS event's contribution to the
  -- batch, the number of cards it moved that the condition admits. A meld's entry
  -- is one event moving two (CR 701.42a); every other move, one. batchBindings
  -- sums the contributions across the group. Unconditional given a match, which
  -- admits a zone change only.
  (TriggerCondition.LeavesZone t, GameEvent.Moved m)
    | LeavesZoneTrigger.batching t == Batching.OneOrMore ->
        Binding.setEventAmount (Natural.length (admittedDepartures gs bearer you t m)) Map.empty
  -- CR 729.4a's crossing moves one card, which the match arm has admitted.
  (TriggerCondition.LeavesZone t, GameEvent.LeftTheGame _)
    | LeavesZoneTrigger.batching t == Batching.OneOrMore ->
        Binding.setEventAmount 1 Map.empty
  -- The card a hand received, under Binding.handArrival rather than CR 400.7e's
  -- `became`, which a hidden destination withholds (CR 400.2). Kithkin
  -- Brinefarer, Volatile Rift and Veteran Ghoulcaller read it.
  (TriggerCondition.LeavesZone _, GameEvent.Moved m)
    | ZoneChange.to (Moved.change m) == Zone.Hand ->
        Binding.setHandArrival (ZoneChange.object (Moved.change m)) Map.empty
  -- CR 603.1b's multi-condition ability, bound as the UNION of what its branches
  -- stamp off this one event -- the only answer that fills a slot two branches
  -- name. Case of the Pilfered Proof's "whenever a Detective you control enters
  -- or is turned face up, put a +1/+1 counter on IT" is the reader: both branches
  -- stamp `became`, so the payload finds the subject whichever one matched.
  --
  -- A BRANCH THE EVENT DID NOT MATCH contributes nothing, this function casing on
  -- (condition, event) PAIRS: a branch watching another event class falls to the
  -- wildcard below. Two branches of one class both stamp, off the SAME event, so
  -- they agree on the id and Map.unions' left bias settles nothing.
  --
  -- Below eventBindingSlots' floor, never above it: that function INTERSECTS, and
  -- an intersection is a subset of every branch's stamps, so every slot it
  -- promises is stamped by whichever branch matched. The slots only some branch
  -- binds are eventBindingSlotsSometimes' AnyOf arm.
  (TriggerCondition.AnyOf conditions, _) ->
    Map.unions (fmap (\c -> eventBindingsOver board gs bearerBecame becameInGraveyard bearer you c event) conditions)
  (TriggerCondition.CausedBy narrowed, _) ->
    eventBindingsOver board gs bearerBecame becameInGraveyard bearer you (CausedBy.condition narrowed) event
  -- The CR 701/702 keyword-action conditions reach this fallthrough and
  -- stamp nothing, deliberately: no card in the pool reads the scrying player,
  -- the plotted card, the explorer or the forager, and
  -- a self-scoped PermanentActs' "it" is the bearer, which CR 113.7a's source slot already
  -- names. eventBindingSlots claims nothing for any of them; see that function's
  -- arms.
  --
  -- CR 705.2's FlipsCoin reaches it too, under either outcome, on the
  -- same reasoning: the winner or loser is CR 109.5's "you", whom Binding.setYou
  -- already names, and Tavern Scoundrel's "create two Treasure tokens" and
  -- Karplusan Minotaur's targeted damage read nothing else off the flip.
  --
  -- CR 603.12's Reflexive reaches it NECESSARILY rather than by choice: it
  -- admits no event at all, so delayedPending never calls this for one and there
  -- is nothing an arm could read. What such an ability knows comes from CR
  -- 603.7c's captured environment instead.
  _ -> Map.empty

-- CR 603.2c's second sentence inside one batch: the seats and objects that
-- split a batch-scoped condition's group into several occurrences, read off the
-- bindings eventBindings stamped for one member. Empty for every other
-- batch-scoped condition, whose group is one occurrence whole.
--
-- For PermanentsDealCombatDamageToPlayer, the damagers' controller and the
-- damaged player. The controller because each printing in data/cards/ names
-- it -- "you control", "an opponent controls" -- and Norn's Decree's "one or
-- more creatures AN OPPONENT controls" is one occurrence per opponent whose
-- creatures connected, CR 726.2's "a player controls" grouped the same way
-- below. The damaged player because CR
-- 506.2a and CR 508.1b let one CR 510.2 step damage several players, and "to
-- a player" is one occurrence per player hit: Feline Sovereign's "that player
-- controls" and The Raven's Warning's "that player's hand" name one seat.
-- Not for "to one or more players" (Forth Eorlingas!), whose eventBindings arm
-- stamps no damaged player.
-- data/scenarios/card-trigger/cr-603-2c-feline-sovereign-triggers-once-per-player-its-cats-hit.json
-- proves the split.
--
-- Not implemented: a batch naming no controller, one occurrence whoever's
-- creatures connected -- Starscream, Power Hungry's "one or more creatures deal
-- combat damage to you" (#4473).
batchPartition :: TriggerCondition -> Map.Map SlotName.SlotName Binding -> Seq.Seq (Either PlayerId ObjectId)
batchPartition cond bindings = case cond of
  -- One occurrence per damager: Noble Purpose's "a creature you control deals
  -- combat damage" fires for each creature that connected in the CR 510.2 step,
  -- and Spirit Link's "deals damage" for its host's one damage event. A Self
  -- reading has one damager, the bearer, so the split leaves it whole, and a
  -- trigger naming a recipient is not batch-scoped at all.
  TriggerCondition.DealsDamage _ -> object Binding.combatDamager
  TriggerCondition.PermanentsDealCombatDamageToPlayer _ -> seat Binding.damagersController <> seat Binding.triggerPlayer
  -- CR 726.2's "one or more creatures A PLAYER controls": one occurrence per
  -- damagers' controller. The damaged player is the holder, one seat already.
  TriggerCondition.CreaturesDealtCombatDamageToInitiative -> seat Binding.damagersController
  -- CR 603.2c: one occurrence per damaged player, and per damaged planeswalker
  -- beside it -- Vengeful Pharaoh's ruling (2011-09-22) that damage to you and
  -- a planeswalker you control at once triggers it twice.
  -- data/scenarios/card-trigger/cr-603-2c-vengeful-pharaoh-triggers-once-for-you-and-once-per-planeswalker.json
  -- proves the split.
  TriggerCondition.PlayerIsDealtDamage _ -> seat Binding.triggerPlayer <> object Binding.became
  -- One occurrence per damaged permanent: Death Pits of Rath's "a creature is
  -- dealt damage" destroys each creature a batch damaged, and Ripjaw Raptor's
  -- Self reading has one.
  TriggerCondition.IsDealtDamage _ -> object Binding.became
  -- CR 601.2c: one occurrence per targeting object, each its own announcement,
  -- even where several land in one group -- Hive Mind's copies, made inside its
  -- ForEach's bracket. data/scenarios/leyline-of-combustion-burns-once-per-hive-mind-copy.json
  -- proves the split.
  TriggerCondition.BecomesTargeted c | BecomesTargetedTrigger.batching c == Batching.OneOrMore -> object Binding.targetingObject
  -- The branch that matched is the one that stamped, eventBindings' AnyOf arm's
  -- reading.
  TriggerCondition.AnyOf conditions -> Maybe.fromMaybe Seq.empty (List.find (not . Seq.null) (fmap (`batchPartition` bindings) conditions))
  TriggerCondition.CausedBy narrowed -> batchPartition (CausedBy.condition narrowed) bindings
  -- A wildcard where batchScoped is exhaustive: a batch condition splits only
  -- where an arm above says by what.
  _ -> Seq.empty
  where
    seat slot = maybe Seq.empty (Seq.singleton . Left) (Map.lookup slot (Binding.playerSlots bindings))
    object slot = maybe Seq.empty (Seq.singleton . Right) (Map.lookup slot (Binding.objectSlots bindings))

-- CR 603.2c's FIRST sentence, read back: a batch-scoped condition's trigger event
-- is the whole Parun.Types.EventGroup (one `batchPartition` key's share of it),
-- so its bindings are the JOIN of what each member it matched contributes, in
-- log order. Binding.amount ADDS across members -- "that many" counts the batch,
-- not its first event -- and Binding.objects appends; every other field keeps
-- Binding.mergeBinding's left bias. Called by both gatherers, eventTriggers and delayedPending, with the
-- per-member eventBindings of every matching member.
--
-- Parun.LeavesTriggerSpec's Rakshasa Vizier group proves the sum: two cards
-- exiled from one graveyard in one group are two Moved events.
batchBindings :: NonEmpty.NonEmpty (Map.Map SlotName.SlotName Binding) -> Map.Map SlotName.SlotName Binding
batchBindings (first NonEmpty.:| rest) = List.foldl' (Map.unionWith join) first rest
  where
    join a b =
      (Binding.mergeBinding a b)
        { Binding.Type.amount = (+) <$> Binding.Type.amount a <*> Binding.Type.amount b <|> Binding.Type.amount a <|> Binding.Type.amount b,
          Binding.Type.objects = Binding.Type.objects a <> Binding.Type.objects b
        }

-- CR 509.3b / 509.3d: whether one end of a block is what the pair's Filter
-- watches, as the event's own board sample shows it (`postEventView`, CR
-- 603.10), so Venom's host is still enchanted after CR 704.5m buried Venom.
admittedAt :: Filter.Context -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> Filter.Type.Filter Keyword.Type.Keyword -> Bool
admittedAt context board gs oid f = maybe False (\view -> Filter.matches context view f) (postEventView board gs oid)

-- CR 509.3: the slots eventBindings stamps for a block trigger. The blocker for
-- CR 509.3a / 509.3e's blocking side (Super-Soldier Serum's "it"), the other
-- creature for CR 509.3b / 509.3d (Loyal Sentry's attacker, flanking's
-- blocker), the attacker and CR 508.5's defending player for CR 509.3c
-- (afflict), and the attacker alone for CR 509.3e's attacking side (Seifer,
-- Balamb Rival), whose arrivals carry no defending player.
blockSlots :: BlockRole.BlockRole -> BlockCount.BlockCount -> Set.Set SlotName.SlotName
blockSlots role count = case (role, count) of
  (BlockRole.Blocker, BlockCount.Once) -> Set.singleton Binding.blockingCreature
  (BlockRole.Blocker, BlockCount.AtLeast {}) -> Set.singleton Binding.blockingCreature
  (BlockRole.Blocker, BlockCount.EachCreature _) -> Set.singleton Binding.blockedCreature
  (BlockRole.Attacker, BlockCount.Once) -> Set.fromList [Binding.attackingCreature, Binding.triggerPlayer]
  (BlockRole.Attacker, BlockCount.AtLeast {}) -> Set.singleton Binding.attackingCreature
  (BlockRole.Attacker, BlockCount.EachCreature _) -> Set.singleton Binding.blockingCreature

-- CR 603.10's first sentence: `oid` as the event's own board sample shows it
-- (Projection.sampledView), and CR 608.2h's last known information for an id
-- the sample does not hold -- one gone before the sample was taken, or any id
-- when the caller has no sample (an empty board).
postEventView :: Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> Maybe Filter.View
postEventView board gs oid = case Map.lookup oid board of
  Just candidate -> Just (Projection.sampledView board oid candidate gs)
  Nothing -> Projection.viewWithLastKnown oid gs oid

-- CR 725.2 / CR 726.2: the creature that dealt this event's COMBAT damage to
-- `victim`, paired with who controlled it. Nothing for any other event, and
-- Nothing for a source that was not a creature then.
--
-- Read off `board`, the event's CR 603.10 sample (Event.Trigger.battlefieldAt),
-- and never last known information: the damager is judged as it stood
-- immediately after the damage, and the CR 704.5g destruction that kills a
-- trampler its blocker traded with is a LATER event, which changeZone answers
-- with a fresh id. Proved by Parun.InitiativeSpec's "CR 726.2 a trampler that
-- trades with its blocker still hands the initiative over".
--
-- Both halves come from the ONE sample, so "was it a creature?" and "whose was
-- it?" cannot be answered about two different boards.
combatDamagerOn :: Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> PlayerId -> GameEvent -> Maybe (ObjectId, PlayerId)
combatDamagerOn board victim event = case event of
  GameEvent.DamageDealt ev
    | DamageEvent.kind ev == DamageKind.Combat && DamageEvent.target ev == Recipient.ToPlayer victim ->
        case Map.lookup (DamageEvent.source ev) board of
          Just candidate
            | Set.member CardType.Creature (PC.cardTypes (BattlefieldCandidate.characteristics candidate)) ->
                Just (DamageEvent.source ev, BattlefieldCandidate.controller candidate)
          _ -> Nothing
  _ -> Nothing

-- The cards a Moved event took out of the condition's zone that its filter
-- admits, read off CR 608.2h's last known information: by the time CR 603.10
-- checks, each is gone from the zone it left. Every departure is asked, not
-- only ZoneChange.departed, since a meld's entry is one event for several cards
-- (CR 701.42a). The zones and the turn are Match.leavesZone's questions, not
-- this one's.
admittedDepartures :: GameState -> ObjectId -> PlayerId -> LeavesZoneTrigger.LeavesZoneTrigger -> Moved.Moved -> Seq.Seq ObjectId
admittedDepartures gs bearer you t = Seq.filter (admitsDeparture gs bearer you t) . Moved.departures

-- Whether the trigger's subject is one departed card, from the pile it names:
-- the bearer by id, or a card its Filter admits off CR 608.2h's last known
-- information.
admitsDeparture :: GameState -> ObjectId -> PlayerId -> LeavesZoneTrigger.LeavesZoneTrigger -> ObjectId -> Bool
admitsDeparture gs bearer you t departed =
  -- CR 400.1: "your graveyard" is the pile the card LEFT, off CR 608.2h's
  -- record -- its owner's except between an ownership change and the move that
  -- follows it (Tempest Efreet), where the owner names the wrong seat.
  let fromWhose = case LeavesZoneTrigger.whose t of
        Nothing -> True
        Just relation -> case Game.lastKnownOf departed gs >>= LastKnown.pile of
          Just holder -> PlayerRelation.holds (Game.teams gs) relation you holder
          Nothing -> False
      watched = case LeavesZoneTrigger.card t of
        ActingPermanent.Self -> departed == bearer
        ActingPermanent.Matching f -> case Projection.viewWithLastKnown departed gs departed of
          Nothing -> False
          Just view -> Filter.matches (Projection.sourceContext gs (Just you) bearer) view f
   in fromWhose && watched

-- CR 615.13 / 120.1: the sources of one prevention that a SelfPreventsDamage
-- Filter admits, each with its per-recipient share, read off CR 608.2h's last
-- known information, zone included, since a source may have left by now. A
-- source whose share is 0 is not admitted: rule 615.13 fires where some damage
-- "is prevented", and CR 615.12's inert application prevented none of that
-- source's. `context` is the caller's, so the match arm can pass the delayed
-- ability's slot objects (CR 603.7c).
admittedPreventedSources :: Filter.Context -> GameState -> Filter.Type.Filter Keyword.Type.Keyword -> DamagePrevented.DamagePrevented -> Map.Map ObjectId (Map.Map Recipient.Recipient Numeric.Natural.Natural)
admittedPreventedSources context gs f = Map.filterWithKey admits . DamagePrevented.amounts
  where
    admits damager share =
      sum share > 0 && maybe False (\view -> Filter.matches context (ProjectionView.lastZoned gs damager view) f) (Projection.viewWithLastKnown damager gs damager)

-- The attackers `attacker` declared that the Filter admits, CR 508.3c's "a
-- creature that player controls" read through Combat.joinedUnder (CR 506.4)
-- and each viewed through viewWithLastKnown, framed by the bearer. CR 508.4's
-- creature put onto the battlefield attacking is not in Combat.declaredAttackers.
admittedAttackers :: GameState -> ObjectId -> PlayerId -> Filter.Type.Filter Keyword.Type.Keyword -> PlayerId -> Seq.Seq ObjectId
admittedAttackers gs bearer you f attacker = Seq.fromList (filter admits (Set.toList (Combat.declaredAttackers combat)))
  where
    combat = GameState.combat gs
    admits oid =
      Map.lookup oid (Combat.joinedUnder combat) == Just attacker
        && maybe False (\view -> Filter.matches (Projection.sourceContext gs (Just you) bearer) view f) (Projection.viewWithLastKnown oid gs oid)

-- CR 508.3: the slots eventBindings stamps for an attack trigger, each off the
-- event its arity matches. A declared or unblocked attacker and CR 508.5's
-- defending player (annihilator's "defending player", exalted's "that
-- creature"); the attacked player under the reserved "that player" slot
-- (Seifer, Balamb Rival's "that player controls"), where the attacked is a
-- player, and CR 508.3e's attacking player beside it (Archnemesis' "attach
-- this Aura to that player"); and the declaring player, with the creatures a
-- count admitted (Tyvar the Bellicose's "they").
attackSlots :: AttackTrigger.AttackTrigger -> Set.Set SlotName.SlotName
attackSlots trigger = case trigger of
  AttackTrigger.Attacker _ -> Set.fromList [Binding.attackingCreature, Binding.triggerPlayer]
  AttackTrigger.Attacked t ->
    Set.fromList
      ( [Binding.triggerPlayer | AttackedTrigger.attacked t /= AttackedSubject.Source]
          <> [Binding.attackingPlayer | Maybe.isJust (AttackedTrigger.attacker t)]
      )
  AttackTrigger.Declaration t -> case DeclarationTrigger.attackers t of
    Nothing -> Set.singleton Binding.attackingPlayer
    Just _ -> Set.fromList [Binding.attackingPlayer, Binding.attackingCreatures]
  AttackTrigger.Unblocked _ -> Set.fromList [Binding.attackingCreature, Binding.triggerPlayer]

-- CR 400.7: what eventBindings stamps for a LeavesZone, as (guaranteed given
-- a match, bound for some matches only). CR 400.7e's `became` is never bound:
-- the trigger admits hidden destinations (CR 400.2), and no payload in the pool
-- names the card. A batch binds CR 603.2c's "that many" (Rakshasa Vizier), each
-- event's share summed by batchBindings. A single card that reached a hand is
-- bound under Binding.handArrival (Kithkin Brinefarer's "that card"),
-- guaranteed when the trigger pins the destination to a hand and bound only
-- sometimes when it names none. A Self subject binds the same: the bearer is
-- the card that left, which the source slot already names.
leavesZoneSlots :: LeavesZoneTrigger.LeavesZoneTrigger -> (Set.Set SlotName.SlotName, Set.Set SlotName.SlotName)
leavesZoneSlots t = case LeavesZoneTrigger.batching t of
  Batching.OneOrMore -> (Set.singleton Binding.eventAmount, Set.empty)
  Batching.EachOccurrence -> case LeavesZoneTrigger.to t of
    Just Zone.Hand -> (Set.singleton Binding.handArrival, Set.empty)
    Just _ -> (Set.empty, Set.empty)
    Nothing -> (Set.empty, Set.singleton Binding.handArrival)

-- CR 603.6: what eventBindings stamps for a PutIntoZone, each guaranteed given a
-- match. CR 400.7e's arrival under `became` (Planar Void's "exile THAT CARD")
-- where `bindsArrival` says so, and nothing otherwise.
putIntoZoneSlots :: PutIntoZoneTrigger.PutIntoZoneTrigger -> Set.Set SlotName.SlotName
putIntoZoneSlots t
  | bindsArrival t = Set.singleton Binding.became
  | otherwise = Set.empty

-- Does a PutIntoZone bind CR 400.7e's arrival? Only a single Matching card's,
-- and only into a public zone, which that rule's proviso asks (CR 400.2). A
-- Self subject's bearer already IS the arriving incarnation, which the source
-- slot names (Narcomoeba, Serra Avatar's "shuffle IT"); a batch names no one
-- card (Dutiful Knowledge Seeker).
bindsArrival :: PutIntoZoneTrigger.PutIntoZoneTrigger -> Bool
bindsArrival t = case PutIntoZoneTrigger.card t of
  ActingPermanent.Self -> False
  ActingPermanent.Matching _ ->
    PutIntoZoneTrigger.batching t == Batching.EachOccurrence && not (Game.isHiddenZone (PutIntoZoneTrigger.to t))

-- CR 603.6a: the slots an entry trigger stamps, by subject: the floor, then
-- those bound only sometimes.
--
-- A Self subject's entrant IS the bearer, so CR 113.7a's source slot already
-- names it and `became` would be a second name for one object. It binds the
-- host it entered attached to ("enters attached to a creature"), as the trigger
-- is placed, so Infinite Reflection copies it even once the Aura has moved on
-- (its ruling, 2012-05-01): through CR 608.2h's record where CR 704.5m buried
-- the Aura before the trigger was placed (CR 704.3), which data/scenarios/copy's
-- Infinite Reflection scenario proves. Only sometimes, since only an entrant
-- attached to an object has one; data/cards/infinite-reflection.json is the
-- reader.
--
-- A Matching subject binds CR 400.7e's `became` in the ENTRY direction: the
-- object that moved is the entrant, and what it became is the permanent now on
-- the battlefield -- ZoneChange.object, the field leavesBindings reads for the
-- same reason. The SAME slot as a death's, CR 400.7e being one rule with two
-- readings. What differs is which object CR 113.7a's source happens to be, a
-- fact about the CONDITION rather than the slot: a self death matches the
-- departing incarnation, so `triggerSource` and `became` are two incarnations of
-- one card, while here the bearer is another permanent entirely. Two slots
-- would have to be kept apart by every reader for a distinction no rule draws
-- -- and Resolve, where the slot is read, never learns which condition placed
-- the ability. The public-zone proviso holds by construction, `to ==
-- Battlefield` having already been required. Bound whatever the Filter admits,
-- creature or not: whether the entrant can RECEIVE what the payload does is the
-- payload's question (CR 120.1a for damage), and a binding that existed only
-- for creatures would make the slot's presence depend on the entrant, which
-- eventBindingSlots cannot express. On the floor, so guaranteed given a match.
--
-- A OneOrMore batch stamps the same entrant as a one-member GROUP, so
-- batchBindings' append joins the whole entry event's entrants under one slot
-- (CR 603.2c) where a recipient would keep only the first: Dunbarrow
-- Revivalist's boon attaches its Role to "one of them", which a choice among the
-- group reads.
entersSlots :: EntersTrigger.EntersTrigger -> (Set.Set SlotName.SlotName, Set.Set SlotName.SlotName)
entersSlots t = case EntersTrigger.permanent t of
  ActingPermanent.Self -> (Set.empty, Set.singleton Binding.attachedHost)
  ActingPermanent.Matching _ -> (Set.singleton Binding.became, Set.empty)

-- CR 603.6a: entersSlots, stamped off the entry eventBindings was reached past.
entersBindings :: GameState -> EntersTrigger.EntersTrigger -> ZoneChange.ZoneChange -> Map.Map SlotName.SlotName Binding
entersBindings gs t zc = case EntersTrigger.permanent t of
  ActingPermanent.Self -> maybe Map.empty (`Binding.setAttachedHost` Map.empty) (Game.hostWithLastKnown entrant gs)
  ActingPermanent.Matching _ -> case EntersTrigger.batching t of
    Batching.EachOccurrence -> Binding.setBecame entrant Map.empty
    Batching.OneOrMore -> Binding.setBecameGroup (Seq.singleton entrant) Map.empty
  where
    entrant = ZoneChange.object zc

-- CR 601.2c / 603.2c: which slots a becomes-targeted trigger binds on every
-- match (eventBindingSlots' floor) and which only sometimes. Every one binds the
-- targeting object, guaranteed given a match: every GameEvent.BecameTarget
-- carries a source, so unlike a departure's `became` there is no shape of the
-- event that withholds it.
--
-- A Self subject binds nothing else: CR 702.21a's "that spell or ability" is
-- the object ward counters and whose controller ward offers the cost to. The
-- TARGETED object is the bearer, already bound as CR 113.7a's source, so it gets
-- no second name. Nor does the controller: Resolve.payerOf reads a slot bound to
-- an object as that object's controller, which is the whole of rule 702.21a's
-- "unless that player pays".
--
-- A Matching subject per permanent adds CR 601.2c's "that creature" read by a
-- bystander: the permanent that became the target, which Cowardice returns to
-- its owner's hand, and only sometimes when includesYou may admit the player
-- instead (Unsettled Mariner). The targeting object beside it is Diffusion
-- Sliver's "counter that spell or ability unless its controller pays {2}".
--
-- A OneOrMore batch adds the targeting object's controller, Leyline of
-- Combustion's "that player", and nothing else: CR 603.2c makes the whole
-- announcement the trigger event, so no one permanent it named is the thing the
-- condition is about. The event's player rather than the object's holder, so a
-- spell countered or stolen before the trigger resolves changes nothing; the
-- Leyline scenario's Aethersnatch proves it. The targeting object is what
-- batchPartition splits a group by.
becomesTargetedSlots :: BecomesTargetedTrigger.BecomesTargetedTrigger -> (Set.Set SlotName.SlotName, Set.Set SlotName.SlotName)
becomesTargetedSlots c = case (BecomesTargetedTrigger.batching c, BecomesTargetedTrigger.permanent c) of
  (Batching.OneOrMore, _) -> (Set.fromList [Binding.targetingObject, Binding.triggerPlayer], Set.empty)
  (Batching.EachOccurrence, ActingPermanent.Self) -> (Set.singleton Binding.targetingObject, Set.empty)
  (Batching.EachOccurrence, ActingPermanent.Matching _)
    | BecomesTargetedTrigger.includesYou c -> (Set.singleton Binding.targetingObject, Set.singleton Binding.became)
    | otherwise -> (Set.fromList [Binding.became, Binding.targetingObject], Set.empty)

-- CR 601.2c / 603.2c: becomesTargetedSlots, stamped off the announcement
-- eventBindings was reached past.
becomesTargetedBindings :: BecomesTargetedTrigger.BecomesTargetedTrigger -> BecameTarget.BecameTarget -> Map.Map SlotName.SlotName Binding
becomesTargetedBindings c t = Binding.setTargetingObject (BecameTarget.source t) $ case (BecomesTargetedTrigger.batching c, BecomesTargetedTrigger.permanent c) of
  (Batching.OneOrMore, _) -> Binding.setTriggerPlayer (BecameTarget.controller t) Map.empty
  (Batching.EachOccurrence, ActingPermanent.Self) -> Map.empty
  (Batching.EachOccurrence, ActingPermanent.Matching _) -> maybe Map.empty (`Binding.setBecame` Map.empty) (Recipient.objectOf (BecameTarget.targeted t))

-- CR 708.7 through CR 603.2: which slots a turned-face-up trigger binds on
-- every match (eventBindingSlots' floor) and which only sometimes.
--
-- A Self subject's floor is a DELIBERATE empty rather than an arm nobody wrote:
-- the event names the permanent, and CR 113.7a's source slot already names it.
-- eventBindings' fallthrough would answer the same for a condition that had been
-- forgotten, which is exactly why it is spelled out here: Parun.TriggerSpec pins
-- the two against each other. Its CR 702.37f / 702.168e X is bound only when the
-- cost that turned the permanent up had an X in it (Warbreak Trumpeter's morph
-- {X}{X}{R}), and never down an effect's road up, which chose none.
--
-- A Matching subject is the same event read by a bystander, and here the floor
-- is NOT empty. CR 113.7a's source slot names the WATCHER rather than the
-- permanent that turned over, so the subject needs a slot of its own, and Pine Walker's "untap that
-- creature" is the printing that reads it. The zone-change slot, widened; see
-- eventBindings' arm for why it is that slot and not a new one.
--
-- ALWAYS bound and never sometimes, which is what Binding.became's own contract
-- demands: GameEvent.TurnedFaceUp carries one ObjectId unconditionally, so
-- unlike CR 400.7e's hidden-destination case (eventBindingSlotsSometimes)
-- there is no shape of this event that withholds it.
turnedFaceUpSlots :: ActingPermanent.ActingPermanent -> (Set.Set SlotName.SlotName, Set.Set SlotName.SlotName)
turnedFaceUpSlots subject = case subject of
  ActingPermanent.Self -> (Set.empty, Set.singleton Binding.variableX)
  ActingPermanent.Matching _ -> (Set.singleton Binding.became, Set.empty)

-- CR 603.6c: which slots a leaves-the-battlefield trigger is GUARANTEED to bind
-- given a match (eventBindingSlots' floor), and which only for some of its
-- departures (eventBindingSlotsSometimes), by subject and destination.
--
-- CR 603.10a's departed permanent (`departedPermanent`) for a bystander or bound
-- subject: one printed "it" is two objects, and a card names whichever its
-- sentence means -- Cleopatra, Exiled Pharaoh's counters and Resourceful
-- Defense's "if it had counters" are the permanent as it last existed, which
-- only CR 608.2h still answers for. Every zone change carries
-- ZoneChange.departed, and a departure from the game carries the id itself.
-- Beside it, CR 400.3's OWNER under `triggerPlayer`, Warped Devotion's "that
-- player discards a card": the zone-change funnel files CR 608.2h's record of the
-- departing id in the same write that deletes it, so it survives CR 704.5d
-- taking a token away. A self subject needs neither: it IS the source.
--
-- CR 400.7e's new object (`became`) where the destination is public (CR 400.2):
-- Promise of Tomorrow's "exile it", Whippoorwill's "exile the creature". The
-- floor where every named destination is public, and only sometimes where the
-- trigger admits a hidden one or any departure at all (CR 603.6c's leaving the
-- game reaches no zone); synthetic-persistent-roaches.json is that reader.
--
-- For an Attached subject `became` is instead CR 400.7f's: the AURA's own
-- incarnation in its owner's graveyard (Screams from Within's "return this
-- card"), on the floor where a destination is named and sometimes where none
-- is, since CR 800.4a can take the Aura from the game with its host.
--
-- Not implemented: the EQUIPMENT bearer of an Attached subject, which CR 704.5n
-- leaves standing, so CR 400.7f mints no incarnation for it and the floor
-- over-claims `became`. The classification is per CONDITION and cannot see the
-- bearer's subtypes; nothing in the pool reads the slot there (Skullclamp's
-- payload names none) (#3153).
--
-- Nothing for a Haunted subject (rule 702.55b's ability speaks about the
-- creature it HAUNTS, never the deceased), and nothing for a OneOrMore batch:
-- batchBindings would join a slot across the batch, and one slot naming one of
-- several departed permanents is no partial binding but a wrong one. No pool
-- card's batch payload reads one (Vengeful Townsfolk, Tameshi, Reality
-- Architect).
leavesSlots :: LeavesTrigger.LeavesTrigger -> (Set.Set SlotName.SlotName, Set.Set SlotName.SlotName)
leavesSlots t
  | LeavesTrigger.batching t == Batching.OneOrMore = (Set.empty, Set.empty)
  | otherwise = case LeavesTrigger.permanent t of
      LeavingPermanent.Haunted -> (Set.empty, Set.empty)
      LeavingPermanent.Attached
        | Set.null destinations -> (Set.singleton Binding.departedPermanent, Set.singleton Binding.became)
        | otherwise -> (Set.fromList [Binding.became, Binding.departedPermanent], Set.empty)
      LeavingPermanent.Self -> arrival
      LeavingPermanent.Matching _ -> bystander
      LeavingPermanent.Bound _ -> bystander
  where
    destinations = LeavesTrigger.destinations t
    public = fmap (not . Game.isHiddenZone . OwnedZone.zone) (Set.toList destinations)
    arrival
      | not (null public) && and public = (Set.singleton Binding.became, Set.empty)
      | null public || or public = (Set.empty, Set.singleton Binding.became)
      | otherwise = (Set.empty, Set.empty)
    bystander = let (always, sometimes) = arrival in (Set.union (Set.fromList [Binding.departedPermanent, Binding.triggerPlayer]) always, sometimes)

-- CR 603.6c: leavesSlots, stamped. `bearerBecame` is the bearer's own CR 400.7f
-- arrival, which an Attached subject binds as `became` in place of the event's
-- arrivals. eventBindings is reached only past a match, so the event is one
-- the trigger admitted.
leavesBindings :: GameState -> Maybe ObjectId -> LeavesTrigger.LeavesTrigger -> GameEvent -> Map.Map SlotName.SlotName Binding
leavesBindings gs bearerBecame t event
  | LeavesTrigger.batching t == Batching.OneOrMore = Map.empty
  | otherwise = case (LeavesTrigger.permanent t, event) of
      (LeavingPermanent.Haunted, _) -> Map.empty
      (LeavingPermanent.Attached, GameEvent.Moved m) -> Binding.setDepartedPermanent (ZoneChange.departed (Moved.change m)) aura
      (LeavingPermanent.Attached, GameEvent.LeftTheGame l) -> Binding.setDepartedPermanent (LeftTheGame.object l) aura
      (LeavingPermanent.Self, GameEvent.Moved m) -> arrival m
      (LeavingPermanent.Self, _) -> Map.empty
      (_, GameEvent.Moved m) -> departed (ZoneChange.departed (Moved.change m)) (arrival m)
      (_, GameEvent.LeftTheGame l) -> departed (LeftTheGame.object l) Map.empty
      _ -> Map.empty
  where
    aura = maybe Map.empty (`Binding.setBecame` Map.empty) bearerBecame
    arrival m
      | Game.isHiddenZone (ZoneChange.to (Moved.change m)) = Map.empty
      | otherwise = setBecameArrivals m Map.empty
    departed oid = maybe id (Binding.setTriggerPlayer . LastKnown.owner) (Game.lastKnownOf oid gs) . Binding.setDepartedPermanent oid

-- CR 508.3: attackSlots, stamped. A trigger whose subject is a player or a
-- permanent and not a creature names no creature, so a Source subject binds
-- nothing a match has not already pinned to the bearer.
attackBindings :: GameState -> ObjectId -> PlayerId -> AttackTrigger.AttackTrigger -> GameEvent -> Map.Map SlotName.SlotName Binding
attackBindings gs bearer you trigger event = case (trigger, event) of
  (AttackTrigger.Attacker _, GameEvent.AttackerDeclared d) ->
    Binding.setTriggerPlayer (AttackerDeclared.defender d) (Binding.setAttackingCreature (AttackerDeclared.attacker d) Map.empty)
  (AttackTrigger.Attacked t, GameEvent.BecameAttacked (BecameAttacked.MkBecameAttacked attacker target)) ->
    let attacked = case (AttackedTrigger.attacked t, target) of
          (AttackedSubject.Source, _) -> id
          (_, AttackTarget.OfPlayer player) -> Binding.setTriggerPlayer player
          _ -> id
        attacking = maybe id (const (Binding.setAttackingPlayer attacker)) (AttackedTrigger.attacker t)
     in attacking (attacked Map.empty)
  (AttackTrigger.Declaration t, GameEvent.AttackersDeclared attacker) -> case DeclarationTrigger.attackers t of
    Nothing -> Binding.setAttackingPlayer attacker Map.empty
    Just count -> Binding.setAttackingPlayer attacker (Binding.setAttackingCreatures (admittedAttackers gs bearer you (AttackCount.filter count) attacker) Map.empty)
  (AttackTrigger.Unblocked _, GameEvent.AttackerUnblocked u) ->
    Binding.setTriggerPlayer (AttackerUnblocked.defender u) (Binding.setAttackingCreature (AttackerUnblocked.attacker u) Map.empty)
  _ -> Map.empty

-- CR 400.7e's `became` slot, in the plural CR 712.21c asks for: "if an effect
-- can find the new object that a melded permanent becomes as it leaves the
-- battlefield, it finds both cards... If that effect causes actions to be taken
-- upon those cards, the same actions are taken upon each of them."
--
-- ONE arrival is bound exactly as it always was -- Binding.toObject, a recipient
-- -- so every ordinary move produces the byte-identical binding it did before
-- this rule landed, and no reader of the slot in data/cards/ can tell the
-- difference. TWO OR MORE are bound as a GROUP (Binding.toObjects), which is
-- the shape Parun.Types.Binding documents for "every object one instruction
-- produced or acted on" and which Parun.Engine.Resolve.Slots.objectRefObjects reads
-- ahead of the recipient path for ObjectRef.InSlot.
--
-- The shape is conditional because the two readers are: an ObjectRef reads
-- either, while a bare SlotName read through Parun.Engine.Resolve's legalOne
-- (Unstable Shapeshifter) reads only the recipient. That reader hangs on a
-- Matching Enters, which cannot split. Every condition that can carry a split
-- is a battlefield DEPARTURE -- CR 712.21's own scope -- and its readers reach the
-- whole group: Promise of Tomorrow, Yedora Grave Gardener and Endless
-- Cockroaches spend the slot as an ObjectRef, and rule 702.55a's haunt
-- (Effect.ExileHaunting under a self death) reads it group first. Screams from
-- Within is NOT among these: its `became` comes from an Attached Leaves, which
-- binds the AURA's own incarnation (`bearerBecame`) rather than the event's
-- arrivals, and no Aura is a meld component.
--
-- No arrival here is a CR 903.9c command-zone component: that split happens
-- only under CR 903.9b's replacement, for a move to a hand or a library, and
-- every arm above that can see such a move binds nothing for a hidden
-- destination (CR 400.7e).
setBecameArrivals :: Moved.Moved -> Map.Map SlotName.SlotName Binding -> Map.Map SlotName.SlotName Binding
setBecameArrivals m = case Moved.arrivals m of
  only Seq.:<| Seq.Empty -> Binding.setBecame only
  every -> Binding.setBecameGroup every

-- Which slots eventBindings above can stamp for a condition, as a set. A
-- CLASSIFICATION of a rule 603 trigger condition -- the sibling of
-- zonesTriggeredFrom below, which asks the other structural question about the
-- same closed type -- so it never reaches an ability's payload and no reader of
-- it learns what any effect IS.
--
-- Its customer is the card lint (CardSpec's "every slot a triggered ability
-- reads is bound for its condition"): an effect naming CR 400.7e's `became` or
-- CR 702.70a's `thatPlayer` under a condition that binds neither would place its
-- trigger, miss the lookup and silently do nothing, which is the worst failure
-- mode card data has.
--
-- Exhaustive with no wildcard, deliberately unlike eventBindings' own
-- `_ -> Map.empty`: that case is over (condition, event) PAIRS, where a wildcard
-- is the only way to say "this pair does not match", while a new CONDITION here
-- must force a decision rather than defaulting to "binds nothing" -- the default
-- that would silently un-lint whatever slot the new condition binds.
--
-- A PARALLEL STATEMENT, PINNED BY A TEST. This says in one dimension what
-- eventBindings says in two, so the two can drift out of agreement. Deriving
-- this from that would mean fabricating a representative GameEvent per condition
-- inside the rules core, which is fixture work the engine has no other use for;
-- the agreement is therefore pinned from the test side instead, by TriggerSpec's
-- "CR 603.2 eventBindingSlots names exactly the keys eventBindings stamps for
-- EVERY event a condition admits", which runs every condition against the events
-- that genuinely fire it and intersects the Map.keysSet of each result against
-- the answer here.
--
-- Every slot named here is GUARANTEED given a match, the only reading that makes a
-- per-CONDITION set sound: the answer must hold for every event the condition
-- admits, the card lint having no event in hand. For most conditions the readings
-- coincide, matchesTrigger having already pinned the destination or recipient.
-- A Leaves admitting a hidden destination is where they come apart, and gets
-- the floor.
eventBindingSlots :: TriggerCondition -> Set.Set SlotName.SlotName
eventBindingSlots cond = case cond of
  -- CR 309.4c names nothing but the room, and the room is in the condition rather
  -- than in the event's bindings. The dungeon card itself arrives under CR 113.7a's
  -- reserved source slot, which every borne trigger gets at placement.
  TriggerCondition.RoomEntered _ -> Set.empty
  -- The acting player, Ob Nixilis, Unshackled's "that player". CR 701.68c's
  -- "blighted creature" and CR 706.2's result are not this condition's to bind:
  -- the INSTRUCTING effect binds each at its own slot (Parun.Types.Blight,
  -- Parun.Types.RollDie).
  TriggerCondition.PlayerActs _ -> Set.singleton Binding.triggerPlayer
  -- Nothing: Withengar Unbound's payload points at no one -- it grows itself.
  TriggerCondition.PlayerLosesGame _ -> Set.empty
  -- Nothing: CR 305.1's land play binds nothing.
  TriggerCondition.PlayerPlaysLand _ -> Set.empty
  -- Nothing: CR 702.170a names an object, but Aloe Alchemist targets a creature
  -- of its controller's choosing rather than pointing at it.
  TriggerCondition.SelfBecomesPlotted -> Set.empty
  -- Nothing: the event names the acting permanent, and no printed payload points
  -- at it as anything but the bearer. Under Self the actor IS the bearer, which
  -- CR 113.7a's source slot already names -- Renegade Krasis' and Savior of
  -- Ollenbock's "this creature", and Glory-Bound Initiate's linked "it" (CR
  -- 701.43d), read as Filter.IsSource. Under a Filter, Wildgrowth Walker grows
  -- itself and Synthetic Veiled Witness draws. A card printing "that creature"
  -- would earn CR 400.7e's slot, as a Matching TurnedFaceUp does.
  TriggerCondition.PermanentActs _ -> Set.empty
  -- Empty as a floor: CR 701.62b fires on a manifest dread that put nothing into
  -- the graveyard, which binds nothing. The `became` it binds otherwise is
  -- eventBindingSlotsSometimes'.
  TriggerCondition.PlayerManifestsDread _ -> Set.empty
  -- The object the sticker went on, for Tusk and Whiskers' "that creature".
  TriggerCondition.PlacesSticker _ -> Set.singleton Binding.became
  TriggerCondition.PlayerRollsResult _ -> Set.empty
  TriggerCondition.Visit -> Set.empty
  TriggerCondition.ChaosEnsues -> Set.empty
  TriggerCondition.PlayerRollsPlaneswalker _ -> Set.empty
  TriggerCondition.SelfTurnedUpOffDeck -> Set.empty
  TriggerCondition.SelfPlaneswalkedAwayFrom -> Set.empty
  TriggerCondition.FlipsCoin _ -> Set.empty
  -- Empty DELIBERATELY. CR 701.3a's event names two objects, and the bearer is
  -- one of them -- CR 113.7a's source slot already names the host. The other,
  -- the attachment, has no printed reader: Bramble Elemental says "create two
  -- 1\/1 green Saproling creature tokens" and names no "it". Enormous Energy
  -- Blade's "tap that creature" reads the event from the other end, under
  -- SelfBecomesAttachedTo below.
  TriggerCondition.SelfBecomesAttachedBy _ -> Set.empty
  -- The other end of the same event, and the one that DOES earn a slot: here the
  -- bearer is the attachment, so CR 113.7a's source slot names it and the host is
  -- a second object. Guaranteed given a match -- matchesTrigger declines a player
  -- host outright.
  TriggerCondition.SelfBecomesAttachedTo _ -> Set.singleton Binding.attachedHost
  -- CR 701.3d's mirror, on its own slot for Parun.Engine.Binding.unattachedHost's
  -- reason.
  TriggerCondition.SelfBecomesUnattachedFrom _ -> Set.singleton Binding.unattachedHost
  -- CR 603.6a: entersSlots has the whole of it.
  TriggerCondition.Enters t -> fst (entersSlots t)
  -- CR 603.2b's step beginning names no OBJECT -- but it names the active player,
  -- and the active player is not what CR 109.5's `you` means, so "that player"
  -- needs a slot of its own. Shizuko, Caller of Autumn is the reader.
  --
  -- Unconditional, as this classification has to be: every GameEvent.StepBegan
  -- carries a PlayerId, whatever the TurnScope.
  TriggerCondition.StepBegins {} -> Set.singleton Binding.triggerPlayer
  -- CR 603.8: a state trigger matches a game STATE rather than an event
  -- (matchesTrigger's StateIs arm answers False for every event), so no event
  -- contributes anything to one.
  TriggerCondition.StateIs _ -> Set.empty
  -- The eventBindings arm's slots: the amount and the damager always, a
  -- recipient's slot where every recipient the trigger names is of its kind.
  TriggerCondition.DealsDamage watched -> fst (damageSlots watched)
  -- CR 120.3's amount for enrage, which Coalhauler Swine's "it deals that much
  -- damage to each player" reads: the same slot CR 615.13's prevention and CR
  -- 119.9's life gain stamp, and guaranteed given a match -- every DamageDealt
  -- event carries an amount, whichever of CR 120.2's two damage kinds this
  -- condition admitted.
  --
  -- Plus, per source, CR 120.1's source, which Belltower Sphinx's "that
  -- source's controller" reads, and equally guaranteed -- every DamageDealt
  -- event carries one. And the recipient under `became`, which Death Pits of
  -- Rath's "destroy it" reads. See the eventBindings arm above.
  TriggerCondition.IsDealtDamage watched -> case PermanentIsDealtDamage.batching watched of
    Batching.EachOccurrence -> Set.fromList [Binding.became, Binding.combatDamager, Binding.eventAmount]
    Batching.OneOrMore -> Set.fromList [Binding.became, Binding.eventAmount]
  -- The damaged player only where no planeswalker can stand in for one.
  TriggerCondition.PlayerIsDealtDamage watched
    | PlayerIsDealtDamage.orTheirPlaneswalkers watched -> Set.singleton Binding.eventAmount
    | otherwise -> Set.fromList [Binding.eventAmount, Binding.triggerPlayer]
  -- The damagers' CONTROLLER and the damaged player where DealsDamage binds
  -- three: the trigger event is a whole CR 510.2 step split by both (CR
  -- 603.2c), so they are the seats every member of an occurrence shares. Norn's
  -- Decree's "that opponent" reads the first, Feline Sovereign's "that player"
  -- the second. The controller alone for "to one or more players", which names
  -- no one damaged player.
  TriggerCondition.PermanentsDealCombatDamageToPlayer p
    | PermanentsDealCombatDamageToPlayer.oneOrMorePlayers p -> Set.singleton Binding.damagersController
    | otherwise -> Set.fromList [Binding.damagersController, Binding.triggerPlayer]
  -- CR 725.2's damaging creature, and CR 726.2's with its controller beside it:
  -- both unconditional given a match, which admits only a creature in the
  -- event's sample, whose view always carries its controller.
  TriggerCondition.CreatureDealtCombatDamageToMonarch -> Set.singleton Binding.triggerSource
  TriggerCondition.CreaturesDealtCombatDamageToInitiative -> Set.fromList [Binding.triggerSource, Binding.damagersController]
  -- CR 726.2's taker is the ability's controller, whom Binding.setYou already
  -- names.
  TriggerCondition.PlayerTookInitiative -> Set.empty
  -- CR 702.94a's revealed card is the bearer itself, already bound as CR 113.7's
  -- source, and the revealing player is its owner -- the same seat CR 113.8 makes
  -- the ability's controller, whom Binding.setYou already names.
  TriggerCondition.SelfRevealedForMiracle -> Set.empty
  -- CR 607.2h's "that card": the card the linked static revealed, which is not
  -- the bearer (God-Eternal Kefnet).
  TriggerCondition.RevealedThisWay _ -> Set.singleton Binding.revealedCard
  -- eventBindings' Discards arm, slot for slot: a Self discard's card is the
  -- bearer, already bound as CR 113.7's source; a Discarder's is CR 400.7e's
  -- `became` (Bag of Holding's "that card") beside the discarding player, whom
  -- the bearer does not name (Megrim's "that player"); a batch counts cards.
  TriggerCondition.Discards trigger -> case (DiscardTrigger.subject trigger, DiscardTrigger.batching trigger) of
    (_, Batching.OneOrMore) -> Set.singleton Binding.eventAmount
    (DiscardSubject.Discarder _, Batching.EachOccurrence) -> Set.fromList [Binding.triggerPlayer, Binding.became]
    (DiscardSubject.Self, Batching.EachOccurrence) -> Set.empty
  -- CR 121.1's drawing player, a discarder's player slot: Underworld Dreams' "that
  -- player" is the opponent who drew.
  TriggerCondition.PlayerDrawsNthCard {} -> Set.singleton Binding.triggerPlayer
  -- CR 508.3: what eventBindings stamps, as a function of the arity and
  -- fields, each guaranteed given a match.
  TriggerCondition.Attacks t -> attackSlots t
  TriggerCondition.Leaves t -> fst (leavesSlots t)
  -- CR 509.3: what eventBindings stamps, as a function of the role and count,
  -- each guaranteed given a match -- every such event carries both ids, and
  -- matchesTrigger has already read the named creature's Filter.
  TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger role _ count) -> blockSlots role count
  TriggerCondition.LeavesZone t -> fst (leavesZoneSlots t)
  TriggerCondition.PutIntoZone t -> putIntoZoneSlots t
  -- CR 701.6a's countering names two objects and a player and this binds none of
  -- them -- eventBindings has no arm for it. Empty by decision rather than
  -- default: both ids are dead by the time the trigger resolves, and CR 400.7e
  -- would name the countered card in its owner's graveyard. A card that says
  -- "exile it instead" is the one that must bind `became` here.
  TriggerCondition.SpellOrAbilityCounters _ -> Set.empty
  -- Empty by the RULE rather than by decision, one step further than the arm
  -- above: CR 701.6a removes a countered ability from the stack and CR 405.1
  -- gives it no card, so there is no `became` for CR 400.7e to withhold or grant.
  -- The countered ability's CR
  -- 113.7 source permanent is a slot that could be bound, and nothing reads it:
  -- the printings that want it -- Green Slime, Teferi's Response, Trickbind --
  -- take it off their own resolution's Counter slot, not off a trigger.
  TriggerCondition.AbilityIsCountered -> Set.empty
  -- CR 615.13's amount, guaranteed given a match: the event carries a Natural
  -- unconditionally, so unlike a departure's `became` there is no
  -- shape of the event that withholds it.
  TriggerCondition.DamageToPlayerPrevented _ -> Set.singleton Binding.eventAmount
  -- The same slot the arm above declares, off the same event: this condition's
  -- payload reads "that much" too. And CR 120.1's source beside it, guaranteed
  -- for the amount's reason -- Parun.Types.DamagePrevented carries an ObjectId
  -- unconditionally, so no shape of the event withholds it.
  TriggerCondition.SelfPreventsDamage _ -> Set.fromList [Binding.eventAmount, Binding.preventedDamageSource]
  -- CR 119.3's amount and the changing player, guaranteed given a match: both
  -- life events carry a Natural and a PlayerId unconditionally, under every
  -- relation. A batch binds nothing, CountersChange's answer: one CR 608.2f
  -- batch may hold a change for every seat, each its own number (Synthetic
  -- Communal Vigil draws a card; CR 702.179d's "your speed" is Binding.setYou's).
  TriggerCondition.LifeChanges lifeTrigger -> case LifeTrigger.batching lifeTrigger of
    Batching.EachOccurrence -> Set.fromList [Binding.eventAmount, Binding.triggerPlayer]
    Batching.OneOrMore -> Set.empty
  -- eventBindings' CountersChange arm, field by field: the amount per permanent,
  -- the object where it is not the bearer and is one permanent. A batch binds
  -- nothing, a OneOrMore Leaves' answer: Cloaked Cadet, the only printing of that
  -- form (Scryfall o:"counters are put on one or more", 2026-08-25), names none
  -- of the permanents, and a printing whose payload said "it" would refute this.
  TriggerCondition.CountersChange counterTrigger ->
    let object = case (CounterTrigger.holder counterTrigger, CounterTrigger.grouping counterTrigger) of
          (CounterHolder.Permanent _, CounterGrouping.EachCounter) -> Set.singleton Binding.became
          (CounterHolder.Permanent _, CounterGrouping.EachPermanent) -> Set.singleton Binding.became
          _ -> Set.empty
        amount = case CounterTrigger.grouping counterTrigger of
          CounterGrouping.EachPermanent -> Set.singleton Binding.eventAmount
          _ -> Set.empty
     in object <> amount
  TriggerCondition.SelfBecomesClassLevel _ -> Set.empty
  -- CR 709.5h names the permanent and the half, and CR 113.7a's source slot
  -- already names the permanent. The HALF is not bound: no printing says "that
  -- door", so there is nothing for a payload to read it as.
  TriggerCondition.SelfHalfUnlocked _ -> Set.empty
  -- CR 709.5i names a permanent the bearer does not have to be, so a slot for it
  -- would be honest -- but no printing reads one ("each opponent loses 1 life"
  -- names nothing about the Room), and eventBindings stamps nothing for this
  -- condition, so claiming one would promise a slot that is never filled.
  TriggerCondition.RoomFullyUnlocked _ -> Set.empty
  -- The INTERSECTION, because this function answers the guaranteed FLOOR: a slot
  -- named here has to be bound for every event the condition admits, and an AnyOf
  -- admits every event any of its branches does. A UNION would promise a slot only
  -- one branch binds, and Parun.Engine.Resolve would look it up on an event the
  -- other branch matched and silently do nothing.
  --
  -- Set.empty for the empty list, which is the floor read literally: an AnyOf
  -- with no branches matches no event, so there is no event for which a slot
  -- could fail to be bound -- but there is also no payload that could ever read
  -- one, and the empty intersection is the only answer a Set can give. No card
  -- writes one; Parun.CardSpec's modal lint is what would notice the ability that
  -- can never fire.
  TriggerCondition.AnyOf conditions -> case fmap eventBindingSlots conditions of
    [] -> Set.empty
    slots : rest -> List.foldl' Set.intersection slots rest
  TriggerCondition.CausedBy narrowed -> eventBindingSlots (CausedBy.condition narrowed)
  TriggerCondition.TurnedFaceUp subject -> fst (turnedFaceUpSlots subject)
  -- A deliberate empty under either subject. A Self one for a Self
  -- TurnedFaceUp's reason one step further on: CR 701.27e's event names the
  -- permanent that transformed, which CR 113.7a's source slot already names,
  -- and the face it turned into is a NAME rather than an object for a slot to
  -- hold. A Matching one because a Matching TurnedFaceUp (turnedFaceUpSlots) is
  -- where the difference would show if a card asked for one: Cult of the Waxing
  -- Moon's payload names the permanent that turned over nowhere, so there is no
  -- subject to claim a slot for. Norn's Inquisitor's "put a +1/+1 counter on
  -- it" is what would take CR 400.7e's slot, exactly as Pine Walker does there.
  TriggerCondition.Transforms _ -> Set.empty
  TriggerCondition.FaceDownPermanentLeavesRevealed -> Set.empty
  -- A deliberate empty: Valeron Wardens draws a card and names no "it", so there
  -- is no subject to claim a slot for. A Matching TurnedFaceUp
  -- (turnedFaceUpSlots) is the worked example of what a card reading the
  -- designated permanent would take -- CR 400.7e's slot, since the event names
  -- one object and CR 113.7a's source names the watcher.
  TriggerCondition.PermanentBecomesDesignated {} -> Set.empty
  -- NOT empty, unlike PermanentActs above, and the pair CR 702.134c names is why:
  -- neither the mentor nor the mentored creature is the bearer, so Aegis of the
  -- Legion's "that creature" has no other name to be read under. Guaranteed given a
  -- match, as this classification has to be: every Mentored event carries both ids.
  TriggerCondition.AttachedCreatureMentors -> Set.singleton Binding.mentoredCreature
  -- The permanent that became tapped or untapped, which the arm above stamps
  -- for every match: Blight destroys it and Mesmeric Orb reads its controller.
  -- Empty for a OneOrMore batch, eventBindings' arm.
  TriggerCondition.BecomesTapState watched -> case BecomesTapState.batching watched of
    Batching.EachOccurrence -> Set.singleton (Binding.tapStatePermanent (BecomesTapState.status watched))
    Batching.OneOrMore -> Set.empty
  -- The permanent tapped for mana, which the arm above stamps for every
  -- match: Wild Growth reads it through PlayerRef.HolderOfBound. The same slot
  -- for the bystander reading and the tapping player beside it.
  TriggerCondition.TappedForMana t -> case TappedForManaTrigger.permanent t of
    TappedPermanent.Attached -> Set.singleton Binding.manaSource
    TappedPermanent.Matching _ -> Set.fromList [Binding.manaSource, Binding.triggerPlayer]
  -- A deliberate empty: Caged Sun's "that color" is the bearer's chosen color,
  -- and it names no source. A card that did would take manaSource.
  TriggerCondition.AbilityAddsMana {} -> Set.empty
  -- The amount the resolving mana ability produced, which the arm above stamps
  -- for every match. No manaSource beside it: the permanent is the bearer.
  TriggerCondition.SelfManaAbilityResolves -> Set.singleton Binding.eventAmount
  -- NOT empty, for AttachedCreatureMentors' reason and not PermanentActs': rule
  -- 702.110b's event names the exploiter, which Binding.triggerSource already
  -- answers, and a SECOND creature besides -- Profaner of the Dead's "the
  -- exploited creature's toughness". Guaranteed given a match, every
  -- GameEvent.Exploited carrying both ids. Either exploiter.
  TriggerCondition.Exploits {} -> Set.singleton Binding.exploitedCreature
  -- NOT empty, unlike PermanentActs above: rule 702.122e's event names the Vehicle,
  -- which Binding.triggerSource already answers, but its rider makes the CREWERS
  -- a subject of their own -- Mighty Servant of Leuk-o's "if it was crewed by
  -- exactly two creatures". Guaranteed given a match, every
  -- GameEvent.BecameCrewed carrying the set.
  --
  -- CR 702.122b's crewer side DOES name somebody the bearer does not: the
  -- Vehicle it crewed, Gearshift Ace's "that Vehicle". Guaranteed given a match,
  -- every GameEvent.Crewed carrying a vehicle.
  TriggerCondition.Crews role -> case role of
    CrewRole.Vehicle _ -> Set.singleton Binding.crewers
    CrewRole.Crewer -> Set.singleton Binding.crewedVehicle
  -- CR 701.21a's event names a player and a permanent, and this claims the
  -- PLAYER: Vengeful Tracker's "deals 2 damage to them" reads the seat that
  -- sacrificed, which the eventBindings arm stamps for every match.
  --
  -- CR 400.7e's new object is NOT guaranteed and so is no member here; it is
  -- claimed by eventBindingSlotsSometimes below, and the eventBindings arm says
  -- what withholds it.
  --
  -- CR 603.10a's departed permanent beside it, guaranteed the same way: the event
  -- carries the pre-move id outright, which is what lets Prowling Geistcatcher's
  -- "if that creature was a token" read a permanent CR 111.7 has already ended.
  TriggerCondition.PermanentSacrificed {} -> Set.fromList [Binding.departedPermanent, Binding.triggerPlayer]
  -- CR 601.2i's spell, the object the event names and nobody the bearer already
  -- does. Guaranteed given a match for the reason CR 615.13's amount is:
  -- GameEvent.SpellCast carries an ObjectId unconditionally, so no shape of the
  -- event withholds it, and unlike a departure's `became` there is
  -- no CR 400.7e proviso to fail. Presence of the Master's "counter it" is what
  -- reads it.
  --
  -- And the CASTER, whom CR 112.2 makes the spell's controller: Kambal, Consul
  -- of Allocation's "that player loses 2 life" reads it, and under that card's
  -- Opponent-scoped Filter the player is not the "you" Binding.setYou names.
  -- Guaranteed for the reason the spell is -- GameEvent.SpellCast carries a
  -- PlayerId unconditionally -- so the promise holds for every cast the Filter
  -- can admit.
  --
  -- A Self subject's is a deliberate empty rather than a default: the spell the
  -- event names is the BEARER, which every ability already reaches as its own
  -- source, and the caster is CR 109.5's "you", whom Binding.setYou already
  -- names. A slot would be a second name for each. eventBindings has no arm for
  -- that subject and its fallthrough answers the same.
  TriggerCondition.SpellCast c -> case SpellCast.spell c of
    ActingPermanent.Self -> Set.empty
    ActingPermanent.Matching _ -> Set.fromList [Binding.castSpell, Binding.triggerPlayer]
  -- The activated ability and its activator, both on every event the condition
  -- admits.
  TriggerCondition.AbilityActivated _ -> Set.fromList [Binding.activatedAbility, Binding.triggerPlayer]
  TriggerCondition.BecomesTargeted c -> fst (becomesTargetedSlots c)
  -- CR 601.2c's targeting object again, a Self BecomesTargeted's one recipient
  -- over: Amulet of Safekeeping's "counter that spell or ability" reads it, and
  -- with a PLAYER targeted there is no bearer-shaped slot that would already
  -- name it. Guaranteed for the sibling's reason -- every GameEvent.BecameTarget
  -- carries a source.
  --
  -- Claimed for the condition rather than for the printing, which is what a
  -- per-CONDITION set means: Dormant Gomazoa's "you may untap this creature"
  -- reads the bearer and never this slot, and a slot promised but unread is
  -- harmless where the reverse is the failure this lint exists to catch.
  TriggerCondition.ControllerBecomesTarget {} -> Set.singleton Binding.targetingObject
  -- CR 603.3b's second class names two things and binds both: CR 113.7's Saga,
  -- which the chapter ability hangs on, under CR 400.7e's slot for the reason
  -- eventBindings' arm gives, and CR 603.3a's controller of that chapter ability
  -- under the reserved player slot. Synthetic Chronicle Warden reads both;
  -- Historian's Boon, the printed bearer, reads neither and is unaffected by the
  -- slots being available.
  --
  -- Both guaranteed given a match: matchesTrigger's arm rejects
  -- TriggerSource.Sourceless, so the record it accepts always carries an
  -- ObjectId, and every record carries a controller. Claimed for the CONDITION
  -- rather than for the printing, which is what a per-condition set means.
  TriggerCondition.SagaFinalChapterTriggers _ -> Set.fromList [Binding.became, Binding.triggerPlayer]
  -- CR 725.1's newly crowned player -- Garland, Royal Kidnapper watches an
  -- OPPONENT take the crown, so the seat is one nothing else on the ability
  -- names. Under the You relation it is also CR 109.5's "you", a second name for
  -- one player and no wrong answer; a per-CONDITION set cannot depend on the
  -- relation.
  --
  -- Unconditional: GameEvent.BecameMonarch carries a PlayerId outright.
  TriggerCondition.PlayerBecomesMonarch _ -> Set.singleton Binding.triggerPlayer
  -- Empty by decision under either subject: the permanent the event names is the
  -- bearer, which the ability already names, or the one the condition's own SLOT
  -- already names, and Ray of Command's "tap it" reads that slot rather than
  -- anything the event bound. A slot for the player who GAINED control is what a
  -- card printing "that player" would earn; nothing prints one.
  TriggerCondition.LosesControl _ -> Set.empty
  -- Empty NECESSARILY rather than by choice: this condition admits no event, so
  -- there is none to read a slot out of. What a reflexive knows about the
  -- resolution that made it comes from CR 603.7c's captured environment instead,
  -- which Parun.Engine.Resolve stamps into the entry as it is armed.
  TriggerCondition.Reflexive -> Set.empty

-- The slots eventBindings stamps for SOME of a condition's events and not for
-- all of them -- what the classification above deliberately leaves out, since a
-- floor may promise only what every admitted event supplies.
--
-- ONE customer, the card lint, which unions this with the floor. A slot bound
-- for some events is a slot a card may legitimately name, because CR 400.7e is
-- itself the rule that withholds it ("if that zone is a public zone"): the
-- payload finding nothing for the other destination is what the rule
-- PRESCRIBES, not the silent no-op the lint exists to catch. Every other reader
-- wants the floor, a slot bound sometimes being no guarantee at all.
--
-- Its arms are a fact about eventBindings above rather than a convenience.
-- Leaves carries CR 400.7e's public-zone proviso and CR 400.7f's Aura that CR
-- 800.4a can take from the game with its host (leavesSlots). PermanentSacrificed
-- is where CR 400.7e's new object is not on the event at all and the arrival
-- table may not carry it -- see that arm. CR 603.1b's AnyOf is where what parts
-- the ceiling from the floor is the BRANCHES disagreeing rather than any one
-- event's shape. LeavesZone with no destination has a Binding.handArrival
-- that turns on the event's `to`. A Self TurnedFaceUp's X only a cost carrying
-- one binds, and PlayerManifestsDread's cards CR 701.62b fires without. The
-- conditional slots that turn on GAME STATE instead -- an Attached Leaves with a
-- destination on CR 400.7f's arrival, a bystander Leaves' owner on CR 608.2h's
-- record -- the floor claims outright, for the reasons leavesSlots gives.
--
-- A WILDCARD here where eventBindingSlots forbids one, the asymmetry being which
-- way each default fails. Defaulting a new condition to "binds nothing" there
-- would silently un-lint a slot it does bind; defaulting to "nothing extra" here
-- only makes the lint STRICTER, and a card rejected at the corpus sweep fails
-- loudly. Pinned even so, by Parun.LeavesTriggerSpec's "CR 603.2 eventBindingSlots
-- and eventBindingSlotsSometimes together name every key eventBindings stamps",
-- which unions where the floor's pin intersects.
eventBindingSlotsSometimes :: TriggerCondition -> Set.Set SlotName.SlotName
eventBindingSlotsSometimes cond = case cond of
  -- The host a Self entrant entered attached to: entersSlots has it.
  TriggerCondition.Enters t -> snd (entersSlots t)
  -- CR 400.7e's and CR 400.7f's proviso where the trigger admits a hidden
  -- destination or none: leavesSlots has the whole of it.
  TriggerCondition.Leaves t -> snd (leavesSlots t)
  -- CR 400.7e's new object again, withheld for a different reason: this event is
  -- CR 603.10a's look-back, recorded before the move, so the arrival is not on it
  -- and eventBindings has to be handed the batch's table instead. A CR 614.1
  -- replacement that redirects the sacrifice leaves the table without the row,
  -- and delayedPending scans no batch at all. data/cards/prowling-geistcatcher.json
  -- is the reader.
  TriggerCondition.PermanentSacrificed {} -> Set.singleton Binding.became
  -- The damaged player for damage to them, the damaged planeswalker for damage
  -- to one: eventBindings' arm binds whichever the event's recipient is. Nothing
  -- in data/cards/ names either under it.
  TriggerCondition.PlayerIsDealtDamage watched
    | PlayerIsDealtDamage.orTheirPlaneswalkers watched -> Set.fromList [Binding.became, Binding.triggerPlayer]
  -- A recipient's slot where the trigger also names a recipient of the other
  -- kind, bound for that kind's damage alone. Garruk's Harbinger admits both
  -- and reads neither.
  TriggerCondition.DealsDamage watched -> snd (damageSlots watched)
  -- Binding.handArrival, bound when the move a destination-free condition
  -- matched reached a hand. Nothing in data/cards/ names it under one.
  TriggerCondition.LeavesZone t -> snd (leavesZoneSlots t)
  -- CR 603.1b's branches disagreeing with each other, which is a fourth way for a
  -- slot to be bound for some of a condition's events and not all: eventBindings
  -- stamps whatever the MATCHED branch does, while the floor above intersects.
  -- Balemurk Leech is the pool's shape -- a Matching Enters binds CR 400.7e's
  -- `became` and RoomFullyUnlocked binds nothing, so a room unlocking leaves the
  -- slot empty and a matching enchantment entering fills it.
  --
  -- The ceiling minus the floor, each branch contributing its own ceiling, so a
  -- branch that itself binds a slot only sometimes is carried through.
  --
  -- WHAT THIS COSTS THE CARD LINT is a shape no printing has: a payload reading
  -- `became` under an AnyOf only one branch binds it for would now pass. The
  -- printed text cannot be written -- "it" has to name something under BOTH
  -- halves of a rule 603.1b sentence, which is why the pool's disjoint pairs
  -- (Balemurk Leech, Bartered Cow) all read nothing at all -- so the floor is
  -- what every real card of this shape needs and this is slack, not a hole.
  TriggerCondition.AnyOf conditions ->
    Set.difference
      (Set.unions (fmap (\c -> Set.union (eventBindingSlots c) (eventBindingSlotsSometimes c)) conditions))
      (eventBindingSlots cond)
  TriggerCondition.CausedBy narrowed -> eventBindingSlotsSometimes (CausedBy.condition narrowed)
  TriggerCondition.TurnedFaceUp subject -> snd (turnedFaceUpSlots subject)
  -- CR 701.62a's cards put into the graveyard, which an empty or one-card
  -- library, or a replacement sending the card elsewhere, leaves without any.
  -- data/cards/paranormal-analyst.json is the reader, and finding nothing there
  -- is the rule's own answer.
  TriggerCondition.PlayerManifestsDread _ -> Set.singleton Binding.became
  TriggerCondition.BecomesTargeted c -> snd (becomesTargetedSlots c)
  _ -> Set.empty

-- CR 603.2 / 120.1: the slots a DealsDamage trigger's eventBindings arm binds,
-- as (always, sometimes). The amount and the damager always; `triggerPlayer`
-- and `became` always where every recipient the trigger names is a player or
-- every one a permanent, sometimes where it names both kinds, and never where
-- it names none.
damageSlots :: DamageTrigger.DamageTrigger -> (Set.Set SlotName.SlotName, Set.Set SlotName.SlotName)
damageSlots watched =
  ( Set.fromList ([Binding.combatDamager, Binding.eventAmount] <> [Binding.triggerPlayer | players, not permanents] <> [Binding.became | permanents, not players]),
    Set.fromList [slot | players, permanents, slot <- [Binding.triggerPlayer, Binding.became]]
  )
  where
    (players, permanents) = namesRecipients watched

-- Whether a DealsDamage trigger names a player recipient, and a permanent one.
namesRecipients :: DamageTrigger.DamageTrigger -> (Bool, Bool)
namesRecipients watched = (any isPlayer recipients, not (all isPlayer recipients))
  where
    recipients = Set.toList (DamageTrigger.recipients watched)
    isPlayer r = case r of
      DamageRecipient.Player _ -> True
      DamageRecipient.Permanent _ -> False
