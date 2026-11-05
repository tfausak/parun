-- The sole casing on TriggerCondition (CR 603.2): does this condition match
-- this event, given the game it happened in. Pure over the condition and the
-- event; the scan that asks it for every trigger source is
-- Parun.Engine.Event.Trigger, and the funnel that raises the events is
-- Parun.Engine.Event. Split out of Parun.Engine.Event for size; nothing here
-- reaches the loop.
module Parun.Engine.Event.Match where

import qualified Control.Monad as Monad
import qualified Data.Foldable as Foldable
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import Numeric.Natural (Natural)
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Condition as Condition
import qualified Parun.Engine.Count as Count
import Parun.Engine.Event.Binding (admitsDeparture, admittedAt, admittedAttackers, admittedDepartures, admittedPreventedSources, combatDamagerOn, postEventView)
import qualified Parun.Engine.Filter as Filter
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.PlayerEffect as PlayerEffect
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Engine.Projection.View as ProjectionView
import qualified Parun.Engine.Replacement as Replacement
import qualified Parun.Engine.Saga as Saga
import qualified Parun.Engine.Turn as Turn
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.AbilityAddsMana as AbilityAddsMana
import qualified Parun.Types.AbilityTriggered as AbilityTriggered
import qualified Parun.Types.AbilityWasActivated as AbilityWasActivated
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.AttackCompany as AttackCompany
import qualified Parun.Types.AttackCount as AttackCount
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackTrigger as AttackTrigger
import qualified Parun.Types.AttackedSubject as AttackedSubject
import qualified Parun.Types.AttackedTrigger as AttackedTrigger
import qualified Parun.Types.AttackerBlocked as AttackerBlocked
import qualified Parun.Types.AttackerDeclared as AttackerDeclared
import qualified Parun.Types.AttackerTarget as AttackerTarget
import qualified Parun.Types.AttackerTrigger as AttackerTrigger
import qualified Parun.Types.AttackerUnblocked as AttackerUnblocked
import qualified Parun.Types.BattlefieldCandidate as BattlefieldCandidate
import qualified Parun.Types.BecameAttached as BecameAttached
import qualified Parun.Types.BecameAttacked as BecameAttacked
import qualified Parun.Types.BecameBlocking as BecameBlocking
import qualified Parun.Types.BecameDesignated as BecameDesignated
import qualified Parun.Types.BecameTarget as BecameTarget
import qualified Parun.Types.BecameUnattached as BecameUnattached
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.BecomesTargetedTrigger as BecomesTargetedTrigger
import Parun.Types.Binding (Binding)
import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.BlockProducer as BlockProducer
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.BlockTrigger as BlockTrigger
import qualified Parun.Types.BlocksDeclared as BlocksDeclared
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CastWindow as CastWindow
import qualified Parun.Types.CausedBy as CausedBy
import qualified Parun.Types.Chosen as Chosen
import qualified Parun.Types.ClassLevelChange as ClassLevelChange
import qualified Parun.Types.CoinFlipped as CoinFlipped
import qualified Parun.Types.Combat as Combat
import qualified Parun.Types.ControlChanged as ControlChanged
import qualified Parun.Types.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.Types.CounterChange as CounterChange
import qualified Parun.Types.CounterHolder as CounterHolder
import qualified Parun.Types.CounterMotion as CounterMotion
import qualified Parun.Types.CounterTrigger as CounterTrigger
import qualified Parun.Types.Countering as Countering
import qualified Parun.Types.CountersPlaced as CountersPlaced
import qualified Parun.Types.Crewing as Crewing
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePrevented as DamagePrevented
import qualified Parun.Types.DamageRecipient as DamageRecipient
import qualified Parun.Types.DamageTrigger as DamageTrigger
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.DeclarationTrigger as DeclarationTrigger
import qualified Parun.Types.DieResult as DieResult
import qualified Parun.Types.DiscardCause as DiscardCause
import qualified Parun.Types.DiscardSubject as DiscardSubject
import qualified Parun.Types.DiscardTrigger as DiscardTrigger
import qualified Parun.Types.DiscardWay as DiscardWay
import qualified Parun.Types.Discarded as Discarded
import qualified Parun.Types.DrawnUnder as DrawnUnder
import qualified Parun.Types.Drew as Drew
import qualified Parun.Types.EntersTrigger as EntersTrigger
import qualified Parun.Types.EventGroup as EventGroup
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.ExploitTrigger as ExploitTrigger
import qualified Parun.Types.Exploited as Exploited
import qualified Parun.Types.Filter as Filter.Type
import Parun.Types.GameEvent (GameEvent)
import qualified Parun.Types.GameEvent as GameEvent
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.HalfUnlocked as HalfUnlocked
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.LandPlayed as LandPlayed
import qualified Parun.Types.LastKnown as LastKnown
import qualified Parun.Types.LeavesTrigger as LeavesTrigger
import qualified Parun.Types.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.Types.LeavingPermanent as LeavingPermanent
import qualified Parun.Types.LeftTheGame as LeftTheGame
import qualified Parun.Types.LifeChange as LifeChange
import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.ManaAbilityResolved as ManaAbilityResolved
import qualified Parun.Types.ManaAdded as ManaAdded
import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ManifestedDread as ManifestedDread
import qualified Parun.Types.Mentored as Mentored
import qualified Parun.Types.Moved as Moved
import qualified Parun.Types.Object as Object
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Types.PermanentIsDealtDamage as PermanentIsDealtDamage
import qualified Parun.Types.PermanentTappedForMana as PermanentTappedForMana
import qualified Parun.Types.PermanentWasSacrificed as PermanentWasSacrificed
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlacesSticker as PlacesSticker
import qualified Parun.Types.PlanarDieFace as PlanarDieFace
import qualified Parun.Types.PlanarDieRolled as PlanarDieRolled
import qualified Parun.Types.Player as Player
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerDrawsNthCard as PlayerDrawsNthCard
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlaysLand as PlaysLand
import qualified Parun.Types.ProjectedCharacteristics as PC
import qualified Parun.Types.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.RevealCause as RevealCause
import qualified Parun.Types.Revealed as Revealed
import qualified Parun.Types.RevealedThisWay as RevealedThisWay
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.SpellWasCopied as SpellWasCopied
import qualified Parun.Types.StepBegan as StepBegan
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.StickerPut as StickerPut
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TappedForMana as TappedForMana
import qualified Parun.Types.Teams as Teams
import qualified Parun.Types.TransformTrigger as TransformTrigger
import qualified Parun.Types.Transformed as Transformed
import Parun.Types.TriggerCondition (TriggerCondition)
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TriggerSource as TriggerSource
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.TurnedFaceUp as TurnedFaceUp
import qualified Parun.Types.TurnedUpOffDeck as TurnedUpOffDeck
import qualified Parun.Types.VentureMarkerEntered as VentureMarkerEntered
import Parun.Types.Zone (Zone)
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange

-- CR 508.3a / 608.2i: how many times this object has been declared as an attacker
-- this turn, read out of the turn-scoped event log. Only Combat.declareAttackers
-- appends the event, which keeps CR 508.4's creature put onto the battlefield
-- attacking -- one that never attacked -- out of the count.
declarationsOf :: ObjectId -> GameState -> Int
declarationsOf bearer gs =
  let declaredIt event = case event of
        GameEvent.AttackerDeclared (AttackerDeclared.MkAttackerDeclared oid _ _ _ _) -> oid == bearer
        _ -> False
   in length (Seq.filter (declaredIt . LoggedEvent.event) (GameState.events gs))

-- CR 508.3: whether `event` fires a Parun.Types.AttackTrigger. Each arity
-- matches its own event, the declaration's three appended by
-- Combat.declareAttackers alone, which is what keeps CR 508.4's creature put onto the battlefield attacking
-- out of every one (CR 508.3a's, 508.3b's and 508.3e's last sentences).
--
-- A declared attacker is read off `board`, CR 603.10's sample (admittedAt):
-- CR 508.1k has already made it attacking, so an Equipment CR 704.5n has
-- unattached since still equips it (data/scenarios's
-- super-soldier-serum-fires-though-the-attack-toll-knocks-it-off-its-host).
attacks :: Filter.Context -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> PlayerId -> AttackTrigger.AttackTrigger -> GameEvent -> Bool
attacks context board gs bearer you trigger event = case (trigger, event) of
  (AttackTrigger.Attacker t, GameEvent.AttackerDeclared d) ->
    let attacker = AttackerDeclared.attacker d
     in admittedAt context board gs attacker (AttackerTrigger.creature t)
          && attackerTargetHolds context gs bearer you (AttackerTrigger.target t) d
          && attackCompanyHolds context gs bearer attacker (AttackerTrigger.company t) d
          && case AttackerTrigger.frequency t of
            TriggerFrequency.EveryTime -> True
            -- "For the first time each turn": the declaration being matched is
            -- already in the log, so "the first time" is "the only one so far",
            -- counted per object, so CR 400.7's new object attacks for the
            -- first time again.
            TriggerFrequency.FirstTimeEachTurn -> declarationsOf attacker gs <= 1
          -- Asked of the live board as triggers are collected, never re-checked
          -- as TriggeredAbility.intervening would be (CR 603.4).
          && maybe True (Condition.holds (Projection.viewWithLastKnownAnywhere gs) context gs bearer) (AttackerTrigger.while t)
  -- CR 508.3b's "is attacked" is once per TARGET: Event.Trigger.batchScoped
  -- collapses the declaration's group. CR 508.3e's "[a player] attacks" is
  -- once per event, each one attacking player and target. Either way only
  -- the target CR 508.1b announced answers, so a creature sent at a
  -- planeswalker leaves a player's trigger silent (CR 508.3e's last sentence).
  (AttackTrigger.Attacked t, GameEvent.BecameAttacked payload) ->
    let enchanted = Recipient.playerOf =<< (Object.attachedTo =<< Game.lookupObject bearer gs)
        attackerHolds = maybe True (\relation -> PlayerRelation.holds (Game.teams gs) relation you (BecameAttacked.attacker payload)) (AttackedTrigger.attacker t)
        attackedHolds = case (AttackedTrigger.attacked t, BecameAttacked.target payload) of
          (AttackedSubject.Related relation, AttackTarget.OfPlayer attacked) -> PlayerRelation.holds (Game.teams gs) relation you attacked
          (AttackedSubject.Enchanted, AttackTarget.OfPlayer attacked) -> enchanted == Just attacked
          (AttackedSubject.Source, AttackTarget.OfPlaneswalker attacked) -> attacked == bearer
          (AttackedSubject.Source, AttackTarget.OfBattle attacked) -> attacked == bearer
          _ -> False
     in attackerHolds && attackedHolds
  -- CR 508.3c / 508.3d: once per declaration, the declaring player read off the
  -- event rather than GameState.activePlayer: under the shared team turns
  -- option each player on the active team is an attacking player (CR 805.10a).
  -- A count's creatures are admittedAttackers, the set eventBindings stamps.
  (AttackTrigger.Declaration t, GameEvent.AttackersDeclared attacker) ->
    PlayerRelation.holds (Game.teams gs) (DeclarationTrigger.player t) you attacker
      && case DeclarationTrigger.attackers t of
        Nothing -> True
        Just count -> Natural.length (admittedAttackers gs bearer you (AttackCount.filter count) attacker) >= AttackCount.floor count
  -- CR 508.3f / 509.1h: the event alone answers it. Combat.blockers would
  -- answer for the board at scan time, and rule 509.1h's last sentence keeps
  -- an attacker whose blockers all left combat blocked. The attacker is read
  -- off `board` too: data/scenarios's
  -- cloak-of-confusion-fires-though-the-block-toll-knocks-it-off-its-host
  -- proves it.
  (AttackTrigger.Unblocked f, GameEvent.AttackerUnblocked u) -> admittedAt context board gs (AttackerUnblocked.attacker u) f
  _ -> False

-- CR 508.3a: whether the declared attacker is attacking what the trigger asks.
attackerTargetHolds :: Filter.Context -> GameState -> ObjectId -> PlayerId -> AttackerTarget.AttackerTarget -> AttackerDeclared.AttackerDeclared -> Bool
attackerTargetHolds context gs bearer you target d = case target of
  AttackerTarget.AnyTarget -> True
  -- CR 508.5 / 508.5a resolve an attacked planeswalker to its controller, and
  -- Combat.declareAttackers stamped that player onto the event.
  AttackerTarget.Defending relation -> PlayerRelation.holds (Game.teams gs) relation you (AttackerDeclared.defender d)
  -- CR 508.1b's announcement, not CR 508.5's defending player: CR 310.9d makes
  -- them different things for a battle. The attacked permanent is a different
  -- object from the bearer, so CR 608.2h's record does not stand in for it.
  AttackerTarget.Permanent f ->
    let admits attacked = maybe False (\view -> Filter.matches context view f) (Projection.viewWithLastKnown bearer gs attacked)
     in case AttackerDeclared.target d of
          AttackTarget.OfPlayer _ -> False
          AttackTarget.OfPlaneswalker attacked -> admits attacked
          AttackTarget.OfBattle attacked -> admits attacked
  -- CR 702.105a names the PLAYER, so an attacked planeswalker does not count.
  -- Non-strict, rule 702.105a's "or tied", over Game.stillPlaying: a player
  -- who has left (CR 800.4a) has no life total left to be beaten.
  AttackerTarget.PlayerWithMostLife -> case AttackerDeclared.target d of
    AttackTarget.OfPlayer attacked ->
      let lifeOf pid = fmap Player.life (Map.lookup pid (GameState.players gs))
       in case lifeOf attacked of
            Nothing -> False
            Just theirs -> all (maybe True (<= theirs) . lifeOf) (Game.stillPlaying gs)
    _ -> False

-- CR 506.5 / 702.149a: whether the rest of the declaration is what the
-- trigger asks.
attackCompanyHolds :: Filter.Context -> GameState -> ObjectId -> ObjectId -> AttackCompany.AttackCompany -> AttackerDeclared.AttackerDeclared -> Bool
attackCompanyHolds context gs bearer attacker company d = case company of
  AttackCompany.AnyCompany -> True
  -- "The ONLY creature declared": one number, never a floor.
  AttackCompany.Alone -> AttackerDeclared.count d == 1
  -- Combat.attackers IS the declaration here: CR 508.2b puts these triggers on
  -- the stack before any player gets priority, so CR 508.4 has had no window to
  -- add a creature, where the turn's log keeps an earlier combat phase's.
  -- Each companion reads through the bearer's last known information (CR
  -- 608.2h), so CR 702.149a's comparison against the source's power holds.
  AttackCompany.WithAnother f ->
    let admits other = other /= attacker && maybe False (\view -> Filter.matches context view f) (Projection.viewWithLastKnown bearer gs other)
     in any admits (Map.keys (Combat.attackers (GameState.combat gs)))

-- CR 509.3e on the effect road (BlockProducer.ByEffect): whether this arrival
-- is the one that answers the attacker's crossing. One effect records a
-- GameEvent.BecameBlocking per arrival, each carrying the same sets before and
-- after, so the crossing is answered on the least arrival and refused on the
-- rest. Parun.CombatCostSpec's SwitchBlockers group proves it for both forms.
answersEffectCrossing :: ObjectId -> Set.Set ObjectId -> Set.Set ObjectId -> Bool
answersEffectCrossing blocker before after = Set.lookupMin (Set.difference after before) == Just blocker

-- CR 509.3: whether `event` fires a Parun.Types.BlockTrigger. The role says
-- which creature of the block the trigger names, and the count which of rule
-- 509.3's events answers it.
--
-- Every creature is read off `board` (admittedAt), CR 603.10's sample, which is
-- rule 509.3f's "at the point" it blocked or became blocked: CR 704.5m may bury
-- an Aura between the declaration and the scan, and the Aura's trigger still
-- fires (data/scenarios's
-- super-soldier-serum-fires-though-the-block-toll-knocks-it-off-its-host and
-- venom-fires-though-the-block-toll-knocks-it-off-the-attacking-host). A
-- creature the sample does not hold is read through CR 608.2h's record.
--
-- A count's creatures come off the EVENT and never off Combat.blockers, which
-- by the time a condition is scanned holds every arrival that came after the one
-- being answered: CR 603.3 puts these triggers on the stack the next time a
-- player would receive priority, and CR 614.16 can double one token-making
-- effect into several arrivals at once.
blocks :: Filter.Context -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> BlockTrigger.BlockTrigger -> GameEvent -> Bool
blocks context board gs (BlockTrigger.MkBlockTrigger role creature count) event =
  let admits = admittedAt context board gs
      tally others = Natural.length . Set.filter (`admits` others)
   in case (role, count, event) of
        -- CR 509.3a: the GROUPED event, which is that rule's "only once each
        -- combat for that creature, even if it blocks multiple creatures". CR
        -- 509.4's creature put onto the battlefield blocking records only a
        -- GameEvent.BecameBlocking, which is rule 509.3a's last sentence.
        (BlockRole.Blocker, BlockCount.Once, GameEvent.BlocksDeclared d) -> admits (BlocksDeclared.blocker d) creature
        -- CR 509.3e on the blocking side, off the same grouped event, so the
        -- printed "one or more" fires once for the whole declaration. Rule
        -- 509.3e's "effects that add or remove blockers" record it too:
        -- Combat.exchangeBlocks (Sorrow's Path), and Parun.CombatCostSpec's
        -- ExchangeBlocks group is the proof.
        (BlockRole.Blocker, BlockCount.AtLeast n others, GameEvent.BlocksDeclared d) ->
          admits (BlocksDeclared.blocker d) creature && tally others (BlocksDeclared.blocked d) >= n
        -- CR 509.3b: the PAIRWISE event, "once for each attacking creature the
        -- creature with the ability blocks". Its last sentence is the producer
        -- guard: data/scenarios/combat-cost's
        -- cr-509-3b-a-creature-put-onto-the-battlefield-blocking-never-blocked
        -- reddens when it is dropped.
        (BlockRole.Blocker, BlockCount.EachCreature others, GameEvent.BecameBlocking b) ->
          BecameBlocking.producer b /= BlockProducer.PutOntoBattlefield
            && admits (BecameBlocking.blocker b) creature
            && admits (BecameBlocking.attacker b) others
        -- CR 509.3c: one event per blocked attacker is what Combat records, so
        -- matching it once is that rule's "only once each combat for that
        -- creature". Parun.TriggerSpec's two-blocker case tells it apart from a
        -- match on GameEvent.BecameBlocking.
        (BlockRole.Attacker, BlockCount.Once, GameEvent.AttackerBlocked a) -> admits (AttackerBlocked.attacker a) creature
        -- CR 509.3d: the pair read from the ATTACKING side, once per blocker.
        -- The producer is deliberately not read: rule 509.3d's fourth sentence is
        -- a form of CR 509.3 that CR 509.4's "never blocked" does not silence (CR
        -- 509.3c's arrival clause is the other), and Parun.CombatCostSpec's
        -- PutOntoBattlefieldBlocking group is the proof.
        (BlockRole.Attacker, BlockCount.EachCreature others, GameEvent.BecameBlocking b) ->
          admits (BecameBlocking.attacker b) creature && admits (BecameBlocking.blocker b) others
        -- CR 509.3e from the attacking side: the BECOMING, which the whole
        -- declaration fires once. `>=` and never `==` is the rule's last
        -- sentence.
        (BlockRole.Attacker, BlockCount.AtLeast n others, GameEvent.AttackerBlocked a) ->
          admits (AttackerBlocked.attacker a) creature && tally others (AttackerBlocked.blockers a) >= n
        -- Rule 509.3e's "effects that add or remove blockers" on CR 509.4's road:
        -- one arrival joining an attacker that was blocked ALREADY (Flash
        -- Foliage's Saproling joining a declared blocker, Aetherplasm), which
        -- crosses the floor rather than clearing it. Removing blockers cannot
        -- reach this: the tally only falls.
        --
        -- BecameBlocking.attackerWasBlocked is "GameEvent.AttackerBlocked was not
        -- also recorded for this arrival": CR 509.3c withholds that event exactly
        -- when the field is set, so the two arms split every arrival between them
        -- and a doubled pair landing on an unblocked attacker fires once. The
        -- producer is load-bearing beside it: Combat.declareBlockers records this
        -- constructor once per declared pair under BlockProducer.Declared, which
        -- the arm above has already answered. Parun.KeywordTriggerSpec's
        -- CreatureBecomesBlockedByAtLeast group is the proof.
        (BlockRole.Attacker, BlockCount.AtLeast n others, GameEvent.BecameBlocking (BecameBlocking.MkBecameBlocking {BecameBlocking.blocker = blocker, BecameBlocking.attacker = attacker, BecameBlocking.producer = BlockProducer.PutOntoBattlefield, BecameBlocking.attackerWasBlocked = True, BecameBlocking.blockersBefore = before})) ->
          admits attacker creature && tally others before < n && tally others (Set.insert blocker before) >= n
        -- The same crossing on the effect road (Combat.switchBlockers, General
        -- Jarkeld), one simultaneous change, answered once on
        -- answersEffectCrossing's arrival. Parun.CombatCostSpec's SwitchBlockers
        -- group is the proof.
        (BlockRole.Attacker, BlockCount.AtLeast n others, GameEvent.BecameBlocking (BecameBlocking.MkBecameBlocking {BecameBlocking.blocker = blocker, BecameBlocking.attacker = attacker, BecameBlocking.producer = BlockProducer.ByEffect after, BecameBlocking.attackerWasBlocked = True, BecameBlocking.blockersBefore = before})) ->
          admits attacker creature && answersEffectCrossing blocker before after && tally others before < n && tally others after >= n
        _ -> False

-- CR 702.122e: how many times the bearer has become crewed this turn --
-- declarationsOf above one rule over, over GameEvent.BecameCrewed rather than
-- the attack declaration. Counted per VEHICLE, and CR 400.7 mints a new object
-- on a zone change, so a Vehicle that left and returned becomes crewed for the
-- first time again.
crewingsOf :: ObjectId -> GameState -> Int
crewingsOf bearer gs =
  let crewedIt event = case event of
        GameEvent.BecameCrewed ev -> Crewing.vehicle ev == bearer
        _ -> False
   in length (Seq.filter (crewedIt . LoggedEvent.event) (GameState.events gs))

-- Clarion Spirit's "your SECOND spell each turn": which of the turn's matching
-- casts this one is, counting from one.
--
-- The window is the whole event log, which is exactly "this turn" for
-- Parun.Engine.PlayerEffect.castsThisTurn's reason -- Engine.handoffTurn clears it
-- at the handoff. So the TurnScope beside the ordinal narrows which turns the
-- ability watches and never which casts are counted; on a turn the scope refuses,
-- the condition has already answered False without reaching here.
--
-- Counted over the casts the SAME condition admits, since the printed sentence
-- puts the ordinal inside the description -- so the Filter and the zone are
-- applied to each earlier cast too. And over the caster's own alone: Mangara, the
-- Diplomat's "an opponent casts THEIR second spell" counts per opponent. Each earlier one is read through
-- Count.snapshotView, the CR 608.2i snapshot its event recorded, because CR
-- 601.2a's stack incarnation is long gone for every cast but the one being
-- matched.
--
-- POSITIONAL rather than a count of the whole log (Game.castsBefore). CR 601.2i
-- files the cast before CR 603.2 checks the condition against it, so the log
-- already holds this cast -- and it may hold LATER ones too, since one CR 117.5
-- boundary can cover several casts. The turn's second cast answers 2 whatever was
-- cast after it. Nothing for a cast the log does not hold, storm's answer: it
-- has no place among the turn's casts, so no ordinal matches it.
--
-- No board tells the walk from a count of the WHOLE log: mutating it away leaves
-- the suite green, because every cast a player can make gets its own CR 117.5
-- scan and no card in the pool casts twice in one resolution -- though a clause
-- list holding two Effect.OfferCast would, and the DSL admits one. So the stop
-- is a fence resting on the rule's ordering rather than a behaviour a test
-- proves.
castOrdinal :: Filter.Context -> Filter.Type.Filter Keyword.Type.Keyword -> Maybe Zone -> PlayerId -> ObjectId -> GameState -> Maybe Natural
castOrdinal context predicate fromZone caster spell gs =
  let counted cast =
        SpellWasCast.player cast == caster
          && maybe True (\z -> SpellWasCast.zone cast == Just z) fromZone
          && maybe False (\view -> Filter.matches context view predicate) (Count.snapshotView (Projection.viewWithLastKnownAnywhere gs) gs (EventShape.SpellCast CastWindow.BeforeEvaluated) (GameEvent.SpellCast cast))
   in fmap ((1 +) . Natural.length . filter counted) (Game.castsBefore spell gs)

-- CR 805.4d: the players whose step this is, among those the scope names, read
-- against `own` as turnScopeAdmits reads it. Every active player for "each
-- player's", each active opponent for "each opponent's", `own` alone for
-- "your", and the active players a PlayersTurn reference names off `bearer` --
-- one seat outside the shared team turns option, where Turn.activePlayers is
-- the active player alone.
stepPlayers :: GameState -> ObjectId -> TurnScope.TurnScope -> PlayerId -> [PlayerId]
stepPlayers gs bearer scope own =
  let admits player = case scope of
        TurnScope.EachTurn -> True
        TurnScope.ControllersTurn -> player == own
        TurnScope.OpponentsTurn -> Teams.areOpponents (Game.teams gs) own player
        TurnScope.PlayersTurn ref -> maybe False (elem player) (Count.scopePlayers (Projection.viewWithLastKnownAnywhere gs) (Projection.sourceContext gs (Just own) bearer) gs ref)
   in filter admits (Turn.activePlayers gs)

-- CR 505.1b: how many main phases have begun this turn, counting the one whose
-- beginning is being matched. GameState.events is cleared at the turn handoff
-- (Parun.Engine.Engine.handoffTurn), so the log is already scoped to the turn the
-- rule scopes the count to, and a phase CR 500.11 skipped records no beginning
-- and so has not "occurred".
--
-- Read off the log at SCAN time rather than stamped on the event, which names
-- the right main phase because no two main phases can begin inside one unscanned
-- window: CR 505.6 gives the active player priority in every main phase, and
-- Parun.Engine.Engine.placePendingTriggers scans at every priority boundary.
--
-- A comprehension rather than a case, so there is no fallthrough arm for a new
-- GameEvent constructor to fall into; `isMainPhase` is exhaustive over Phase.
mainPhasesBegun :: GameState -> Natural
mainPhasesBegun gs =
  Natural.length
    ( do
        GameEvent.StepBegan (StepBegan.MkStepBegan phase _) <- fmap LoggedEvent.event (Foldable.toList (GameState.events gs))
        Monad.guard (isMainPhase phase)
        pure ()
    )

-- CR 505.1: the precombat and postcombat main phases, and no step of any other.
isMainPhase :: Phase.Phase -> Bool
isMainPhase phase = case phase of
  Phase.PrecombatMain -> True
  Phase.PostcombatMain -> True
  Phase.Beginning _ -> False
  Phase.Combat _ -> False
  Phase.Ending _ -> False

-- CR 122: the object, count before and count after of a counter event moving
-- the trigger's kind its way, CR 122.6a's putter read against `you`; Nothing
-- for every other event.
countersMoved :: GameState -> PlayerId -> CounterTrigger.CounterTrigger -> GameEvent -> Maybe (ObjectId, Natural, Natural)
countersMoved gs you counterTrigger event = case (CounterTrigger.motion counterTrigger, event) of
  (CounterMotion.Put relation, GameEvent.CountersPut (CountersPlaced.MkCountersPlaced putter oid kind before after))
    | kind == wanted && PlayerRelation.holds (Game.teams gs) relation you putter -> Just (oid, before, after)
  (CounterMotion.Removed, GameEvent.CountersRemoved (CounterChange.MkCounterChange oid kind before after))
    | kind == wanted -> Just (oid, before, after)
  _ -> Nothing
  where
    wanted = CounterTrigger.kind counterTrigger

-- CR 603.6a: a permanent entered the battlefield, an entry that may trigger
-- `you`'s abilities (`entryTriggers`), and it is the permanent the trigger
-- watches. The subject, by ActingPermanent:
--
-- - Self compares the entrant's id with the bearer's, reading nothing about it.
-- - Matching reads the entrant off `board` (Event.Binding.postEventView), CR
--   603.10's battlefield immediately after the entry, and not the live one: CR
--   704's pass may since have buried what pumped it. Parun.CardTriggerSpec's
--   "CR 603.10 a Kongming that entered as a 3/3 pays nothing" proves it. Never
--   the snapshot the Moved event carries: that is the object as it last existed
--   in the zone it LEFT, and would answer CR 603.6b backwards. An entrant the
--   sample does not hold that is gone and filed no last known information
--   matches nothing. The bearer frames the match rather than being it -- it is
--   the Filter.Context's source (so `Not IsSource` is Soul Warden's "another"),
--   and its controller is CR 109.5's "you" in "a creature you control enters".
--
-- Batching is not read here, `leaves`' reason: `batchScoped` plus
-- eventTriggers' dedup fires a Batching.OneOrMore trigger once (CR 603.2c).
enters :: Filter.Context -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> PlayerId -> EntersTrigger.EntersTrigger -> GameEvent -> Bool
enters context board gs bearer you t event = case Game.enteredBattlefieldChange event of
  Nothing -> False
  Just zc -> watched (ZoneChange.object zc) && entryTriggers gs you zc
  where
    watched entrant = case EntersTrigger.permanent t of
      ActingPermanent.Self -> entrant == bearer
      ActingPermanent.Matching f -> maybe False (\view -> Filter.matches context view f) (postEventView board gs entrant)

-- CR 603.6c: a permanent left the battlefield for a destination the trigger
-- admits, and it is the permanent the trigger watches. An empty destination set
-- admits any zone and CR 603.6c's leaving-the-game form too (CR 800.4a, 729.4a);
-- a named one admits neither, since leaving the game reaches no zone. The `/=
-- Battlefield` guard is against recordMintedArrival's pseudo-move.
--
-- Matched on ZoneChange.departed, never the CR 400.7 incarnation the card
-- became: CR 603.10a makes leaves-the-battlefield abilities look back in time,
-- so every subject is asked about the permanent as it was immediately before the
-- event.
--
-- An owned destination reads CR 400.3's owner off CR 608.2h's record (a stolen
-- Enigma Sphinx is not put into "your graveyard"), and only where the relation
-- asks about a player at all.
--
-- The subject, by LeavingPermanent:
--
-- - Self compares ids and reads no characteristic, so no last known information.
-- - Matching reads its Filter off CR 608.2h's last known information
--   (viewWithLastKnown aimed at the departed id twice over, which takes the
--   last-known branch only once that id is gone). A dead permanent has no live
--   reading, and the graveyard card would answer "you control" for its OWNER
--   (CR 108.4a). A permanent that filed no last known information matches
--   nothing.
-- - Attached reads the departed host's own record of what was attached to it
--   (LastKnown.attached), filed from the pre-move board: CR 704.5m buries an
--   Aura and CR 704.5n unattaches an Equipment in the same SBA batch, so the
--   bearer no longer says what it was attached to. CR 301.5f makes an
--   Equipment's link the same as CR 303.4m makes an Aura's.
-- - Haunted compares against the id GameState.haunting files the bearer under,
--   which rule 702.55b keeps "regardless of whether or not that object is still
--   a creature", so no characteristic is read.
-- - Bound compares against the object CR 603.7c's captured environment named,
--   read out of `bindings` through Binding.objectSlots.
--
-- Batching is not read here: this matcher sees one event at a time, so a
-- Batching.OneOrMore trigger answers True for every member of its CR 704.3 /
-- 608.2f batch, and `batchScoped` plus eventTriggers' dedup within each
-- Parun.Types.EventGroup is what fires it once (CR 603.2c).
leaves :: Map.Map SlotName.SlotName Binding -> Filter.Context -> GameState -> ObjectId -> PlayerId -> LeavesTrigger.LeavesTrigger -> GameEvent -> Bool
leaves bindings context gs bearer you t event = case event of
  GameEvent.Moved (Moved.MkMoved zc _ _ _ _ _ _ _) ->
    ZoneChange.from zc == Zone.Battlefield
      && ZoneChange.to zc /= Zone.Battlefield
      && (Set.null destinations || any (reaches (ZoneChange.to zc) (ZoneChange.departed zc)) destinations)
      && watched (ZoneChange.departed zc)
  GameEvent.LeftTheGame l -> Set.null destinations && LeftTheGame.from l == Zone.Battlefield && watched (LeftTheGame.object l)
  _ -> False
  where
    destinations = LeavesTrigger.destinations t
    reaches to departed (OwnedZone.MkOwnedZone zone owner) =
      to == zone
        && (PlayerRelation.perspectiveFree owner || maybe False (PlayerRelation.holds (Game.teams gs) owner you) (Game.ownerWithLastKnown departed gs))
    watched departed = case LeavesTrigger.permanent t of
      LeavingPermanent.Self -> departed == bearer
      LeavingPermanent.Matching f -> maybe False (\view -> Filter.matches context view f) (Projection.viewWithLastKnown departed gs departed)
      LeavingPermanent.Attached -> maybe False (Set.member bearer . LastKnown.attached) (Game.lastKnownOf departed gs)
      LeavingPermanent.Haunted -> Map.lookup bearer (GameState.haunting gs) == Just departed
      LeavingPermanent.Bound slot -> Map.lookup slot (Binding.objectSlots bindings) == Just departed

-- CR 400.7: a card left the zone the trigger names, for the destination it
-- names or any, from the pile it names or any, on a turn the scope admits.
-- Whose pile is read off the pile CR 608.2h recorded
-- (Event.Binding.admitsDeparture). A card exiled from exile left nothing (CR
-- 400.8, Game.leftOrigin).
--
-- ANY of Moved.departures admits, not only ZoneChange.departed: a meld's entry
-- is one event naming every card that left exile (CR 701.42a, CR 712.14c).
--
-- The subject, by ActingPermanent:
--
-- - Self compares ids: by CR 113.6k the bearer IS the departing card (Oglor,
--   Devoted Assistant's grant), which only eventTriggers' look-back offers.
-- - Matching reads its Filter off CR 608.2h's last known information: the card
--   is no longer in the zone it left by the time CR 603.10 checks. A bearer
--   absent from the board sees the move only where all players could see it
--   (Moved.revealed), CR 603.10a's look-back reaching such a move only then.
--   Parun.LeavesTriggerSpec's "CR 603.10a an exiled Kithkin Brinefarer" cases
--   are the proof.
--
-- The turn comes from the GAME STATE: no characteristic of the departing card
-- says whose turn it is, and CR 109.5 with CR 603.3a fixes "you" as the
-- ability's controller.
--
-- GameEvent.LeftTheGame is CR 729.4a's crossing out of the zone the trigger
-- names, admitted only where it names no destination: leaving the game reaches
-- no zone. Parun.OutsideTheGameSpec's Spirit Mascot case proves it.
--
-- Batching is not read here, `leaves`' reason.
leavesZone :: Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> PlayerId -> (LeavesZoneTrigger.LeavesZoneTrigger -> Bool) -> LeavesZoneTrigger.LeavesZoneTrigger -> GameEvent -> Bool
leavesZone board gs bearer you admitsTurn t event = case event of
  GameEvent.Moved m
    | ZoneChange.from (Moved.change m) == LeavesZoneTrigger.from t,
      Game.leftOrigin (Moved.change m),
      maybe True (== ZoneChange.to (Moved.change m)) (LeavesZoneTrigger.to t) ->
        admitsTurn t
          && seen (Moved.revealed m)
          && not (Seq.null (admittedDepartures gs bearer you t m))
          && entryTriggers gs you (Moved.change m)
  GameEvent.LeftTheGame l
    | LeftTheGame.from l == LeavesZoneTrigger.from t,
      Maybe.isNothing (LeavesZoneTrigger.to t) ->
        admitsTurn t && admitsDeparture gs bearer you t (LeftTheGame.object l)
  -- CR 730.3's departure split, whose origin is the battlefield.
  _ -> False
  where
    seen revealed = case LeavesZoneTrigger.card t of
      ActingPermanent.Self -> True
      ActingPermanent.Matching _ -> Map.member bearer board || revealed

-- CR 603.6: a card was put into the zone the trigger names, from a zone it
-- admits, on a turn the scope admits, and -- for CR 702.55a's haunt -- as the
-- last step of its own resolution (CR 608.2n), which a countered spell (CR
-- 701.6a) and a fizzled one (CR 608.2b) escape.
--
-- Every logged move into the zone is an arrival: reordering a library puts no
-- card into one (Wan Shi Tong, All-Knowing's ruling) and logs nothing
-- (Event.alreadyIn), while a card exiled from exile is a new object (CR 400.8).
--
-- Matched on ZoneChange.object, the ARRIVING card. TWO EVENTS, which is CR
-- 712.21's own Example: the Moved event names the first card a melded
-- permanent's departure puts into the zone and a CardArrived event names each
-- card after it, so such a death fires a per-card trigger twice. A CardArrived
-- is never CR 608.2n's move, nor a move from anywhere but the battlefield.
-- Parun.MutateSpec's "from either arrangement" case proves it over both orders.
--
-- The subject, by ActingPermanent:
--
-- - Self compares ids: the bearer is CR 400.7's new incarnation in the zone it
--   arrived in (Narcomoeba, Serra Avatar), which CR 113.6k makes the zone its
--   ability functions from.
-- - Matching reads its Filter off the arrival, CR 603.10's after-the-event
--   reading: viewWithLastKnown aimed at the arriving card twice over, for the
--   card that has left again by the CR 117.5 boundary. Not the departed object:
--   a merged permanent is one departure and one arrival per component (CR
--   730.3), and CR 730.2d makes it a token whenever its topmost component is
--   one. Parun.LeavesTriggerSpec's "CR 730.3 a merged token put into a library"
--   case is the proof. The bearer frames the match: it is the Filter.Context's
--   source, and its controller is CR 109.5's "you".
--
-- Whether a Matching trigger sees a move its bearer did not stand through is
-- CR 603.10a's question, `putIntoZoneLooksBack`. One that looks back sees a
-- move all players could see (Moved.revealed), its bearer's own departure
-- included. One that does not never sees its bearer's own departure from the
-- battlefield: by CR 603.10's first sentence the bearer is not among the
-- objects that exist immediately after the event, though eventTriggers offers
-- it its own move, and `Not IsSource` (Planar Void's "another") cannot exclude
-- it, CR 400.7 having minted the arrival a fresh id.
--
-- Batching is not read here, `leaves`' reason.
putIntoZone :: Filter.Context -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> PlayerId -> (PutIntoZoneTrigger.PutIntoZoneTrigger -> Bool) -> PutIntoZoneTrigger.PutIntoZoneTrigger -> GameEvent -> Bool
putIntoZone context board gs bearer you admitsTurn t event = case event of
  GameEvent.Moved m -> admits (Moved.revealed m) (Moved.duringResolution m) (Moved.change m)
  GameEvent.CardArrived zc -> admits True False zc
  _ -> False
  where
    origins = PutIntoZoneTrigger.from t
    admits revealed duringResolution zc =
      ZoneChange.to zc == PutIntoZoneTrigger.to t
        && (Set.null origins || Set.member (ZoneChange.from zc) origins)
        && (duringResolution || not (PutIntoZoneTrigger.duringResolution t))
        && admitsTurn t
        && entryTriggers gs you zc
        && watched revealed zc
    watched revealed zc = case PutIntoZoneTrigger.card t of
      ActingPermanent.Self -> ZoneChange.object zc == bearer
      ActingPermanent.Matching f ->
        (Map.member bearer board || revealed)
          && (putIntoZoneLooksBack t || ZoneChange.departed zc /= bearer)
          && let arrived = ZoneChange.object zc
              in maybe False (\view -> Filter.matches context view f) (Projection.viewWithLastKnown arrived gs arrived)

-- CR 603.10a's third and fourth families for a card leaving a zone: a card
-- leaving a graveyard, or one put into a hand or library (CR 400.2's hidden
-- zones). Parun.LeavesTriggerSpec's "CR 603.10a an exiled Kithkin Brinefarer
-- looks back" cases are the proof of the second.
leavesZoneLooksBack :: LeavesZoneTrigger.LeavesZoneTrigger -> Bool
leavesZoneLooksBack t = LeavesZoneTrigger.from t == Zone.Graveyard || maybe False Game.isHiddenZone (LeavesZoneTrigger.to t)

-- CR 603.10a's fourth family, "put into a hand or library" (CR 400.2's hidden
-- zones), and its first: CR 603.6c makes "put into [a zone] from the
-- battlefield" a leaves-the-battlefield ability (Ketramose, the New Dawn's
-- "from graveyards and/or the battlefield"). Parun.LeavesTriggerSpec's "CR
-- 603.10a an exiled Seeker looks back at" cases are the proof of the first.
putIntoZoneLooksBack :: PutIntoZoneTrigger.PutIntoZoneTrigger -> Bool
putIntoZoneLooksBack t = Game.isHiddenZone (PutIntoZoneTrigger.to t) || Set.member Zone.Battlefield (PutIntoZoneTrigger.from t)

-- CR 120.3: was this damage dealt to a player `related` admits, or, with
-- `orTheirPlaneswalkers`, to a planeswalker such a player controls (CR 120.3c)?
-- The planeswalker is judged through `board` as damageBy's Filter is: the
-- damage that empties it of loyalty buries it (CR 704.5i) before the log is
-- scanned, and it was a planeswalker that player controlled when it was dealt.
dealtToRelated :: Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> (PlayerId -> Bool) -> Bool -> Recipient.Recipient -> Bool
dealtToRelated board gs related orTheirPlaneswalkers target
  | Just pid <- Recipient.playerOf target = related pid
  | orTheirPlaneswalkers,
    Just oid <- Recipient.objectOf target =
      maybe False theirPlaneswalker (postEventView board gs oid)
  | otherwise = False
  where
    theirPlaneswalker view = Set.member CardType.Planeswalker (Filter.cardTypes view) && maybe False related (Filter.controller view)

-- CR 603.6a / 613.11: may this zone change trigger `you`'s abilities, or is
-- it a move onto the battlefield that an effect applying to them (Hushwing
-- Gryff) silences? Every arm a move onto the battlefield can satisfy asks: the
-- CR 603.6a arm, the departure-side LeavesZone, since the entry and the
-- departure are one event (docs/decisions.md, "A silenced entry silences its
-- departure"), and PutIntoZone. Any other move answers True, and an event
-- riding the entry (a lore counter, an attachment) is not asked
-- (docs/decisions.md, "An entry's own triggers are the zone change's").
-- PutIntoZone's gate is a regression fence: no card in data/cards names the
-- battlefield as its destination (grep, 2026-10-28).
--
-- Asked of the game filed immediately after the entry
-- (GameState.boardAfterEvent), so a silencer that entered beside the entrant,
-- or is the entrant, counts. The live game answers for an entry none is filed
-- for. That the filed board is read rather than the live one is a regression
-- fence: the suite stays green under the live read, since no scenario has a
-- silencer leave between the entry and the scan.
entryTriggers :: GameState -> PlayerId -> ZoneChange.ZoneChange -> Bool
entryTriggers gs you zc =
  ZoneChange.to zc /= Zone.Battlefield
    || not (PlayerEffect.silencesEntry you (ZoneChange.object zc) (atEntry gs (ZoneChange.object zc)))

-- CR 603.2d: how many additional times an ability of `you`'s that this zone
-- change caused to trigger triggers -- none unless it is a move onto the
-- battlefield (Yarok, the Desecrated), with the scope `entryTriggers` has.
-- Read off the same filed game as `entryTriggers`, so a Yarok entering beside
-- the entrant, or being it, counts (its ruling).
additionalEntryTriggers :: GameState -> PlayerId -> ZoneChange.ZoneChange -> Natural
additionalEntryTriggers gs you zc
  | ZoneChange.to zc == Zone.Battlefield = PlayerEffect.additionalEntryTriggers you (ZoneChange.object zc) (atEntry gs (ZoneChange.object zc))
  | otherwise = 0

-- CR 603.2d: how many additional times `bearer`'s triggered ability triggers on
-- the event of `group`, for a bearer that was a permanent then (CR 110.1): a card
-- in a graveyard or an emblem has no such abilities. Read off the board the
-- ability itself reads: CR 603.10's after the event (GameState.boardAfterEvent),
-- or for `looksBack` the board before it (GameState.boardBeforeEvent; CR
-- 603.10a, 603.10b, 603.10c, 603.10d, 603.10f; CR 603.2d's count is taken in that
-- look-back: Teysa Karlov's and Drivnod's rulings count a doubler that left in the
-- event, whether the ability's permanent stays or leaves). A look-back ability's event with
-- no such board left the battlefield as it was: CR 701.6a's countering and CR
-- 701.31's planeswalking move no permanent, so the after board answers.
additionalTriggers :: GameState -> PlayerId -> ObjectId -> EventGroup.EventGroup -> Bool -> Natural
additionalTriggers gs you bearer group looksBack =
  let after = Map.findWithDefault gs group (GameState.boardAfterEvent gs)
      before = if looksBack then Maybe.maybeToList (Map.lookup group (GameState.boardBeforeEvent gs)) else []
   in case filter (Set.member bearer . GameState.battlefield) (before <> [after]) of
        board : _ -> PlayerEffect.additionalTriggers you bearer board
        [] -> 0

-- The game filed immediately after `entrant` entered the battlefield
-- (GameState.boardAfterEvent), or the live game for an entry none is filed for.
atEntry :: GameState -> ObjectId -> GameState
atEntry gs entrant = maybe gs (\group -> Map.findWithDefault gs group (GameState.boardAfterEvent gs)) (Game.entryGroup entrant gs)

-- CR 603.2: can any trigger condition read this event? The one exhaustive answer
-- about events in trigger matching: a new GameEvent constructor stops the build
-- here and nowhere else, since the arms of matchesTriggerGiven fall through on
-- events they don't read. True promises that an arm reads it; False skips every
-- arm, so an arm added for a False event never fires until this changes.
anyTriggerReads :: GameEvent -> Bool
anyTriggerReads event = case event of
  GameEvent.Moved {} -> True
  GameEvent.CardArrived {} -> True
  GameEvent.DamageDealt {} -> True
  GameEvent.DamagePrevented {} -> True
  GameEvent.StepBegan {} -> True
  GameEvent.SpellCast {} -> True
  GameEvent.SpellCopied {} -> True
  GameEvent.BecameMonarch {} -> True
  GameEvent.TookInitiative {} -> True
  GameEvent.Discarded {} -> True
  GameEvent.Milled {} -> False
  GameEvent.Drew {} -> True
  GameEvent.AttackerDeclared {} -> True
  GameEvent.BecameAttacked {} -> True
  GameEvent.AttackersDeclared {} -> True
  GameEvent.BecameBlocking {} -> True
  GameEvent.AttackerBlocked {} -> True
  GameEvent.AttackerUnblocked {} -> True
  GameEvent.BlocksDeclared {} -> True
  GameEvent.Revealed {} -> True
  GameEvent.Looked {} -> False
  GameEvent.Voted {} -> False
  GameEvent.VotesRevealed {} -> False
  GameEvent.SpellCountered {} -> True
  GameEvent.AbilityCountered {} -> True
  GameEvent.LifeLost {} -> True
  GameEvent.LifeGained {} -> True
  GameEvent.AbilityActivated {} -> True
  GameEvent.CountersPut {} -> True
  GameEvent.CountersRemoved {} -> True
  GameEvent.HalfUnlocked {} -> True
  GameEvent.TurnedFaceUp {} -> True
  GameEvent.Transformed {} -> True
  GameEvent.BecameDesignated {} -> True
  GameEvent.Mentored {} -> True
  GameEvent.Exploited {} -> True
  GameEvent.Convoked {} -> False
  GameEvent.Crewed {} -> True
  GameEvent.BecameCrewed {} -> True
  GameEvent.Saddled {} -> False
  GameEvent.PermanentSacrificed {} -> True
  GameEvent.AbilityTriggered {} -> True
  GameEvent.ControlChanged {} -> True
  GameEvent.VentureMarkerEntered {} -> True
  GameEvent.BecameTarget {} -> True
  GameEvent.BecameAttached {} -> True
  GameEvent.BecameUnattached {} -> True
  GameEvent.LeftTheGame {} -> True
  GameEvent.ArrivedUnseen {} -> False
  GameEvent.LostTheGame {} -> True
  GameEvent.LandPlayed {} -> True
  GameEvent.ManifestedDread {} -> True
  GameEvent.DieResultSettled {} -> True
  GameEvent.RolledToVisit {} -> True
  GameEvent.PlanarDieRolled {} -> True
  GameEvent.TurnedUpOffDeck {} -> True
  GameEvent.ChaosEnsued {} -> True
  GameEvent.ClassLevelSet {} -> True
  GameEvent.Plotted {} -> True
  GameEvent.BecameTapped {} -> True
  GameEvent.BecameUntapped {} -> True
  GameEvent.TappedForMana {} -> True
  GameEvent.ManaAdded {} -> True
  GameEvent.ManaAbilityResolved {} -> True
  GameEvent.CoinFlipped {} -> True
  GameEvent.ActivatedAbilityResolved {} -> False
  GameEvent.TriggeredAbilityResolved {} -> False
  GameEvent.PermanentActed {} -> True
  GameEvent.PlayerActed {} -> True
  GameEvent.StickerPut {} -> True

-- The same question against a slot environment, for the conditions whose subject
-- is an object named EARLIER rather than the bearer or a class of objects
-- (TriggerCondition.LoseControlOfBound, and Leaves of LeavingPermanent.Bound).
-- Projection.controllerOf's `-Given` shape: the plain name above defaults the extra
-- argument, so a caller with nothing to say says nothing.
--
-- An empty map is not a special case -- it simply names no slot, so the arms
-- that read a slot find none and answer False.
--
-- `board` is CR 603.10's first sentence: the battlefield immediately after the
-- event (Event.Trigger.battlefieldAt), for an arm that must not read the live one.
matchesTriggerGiven :: Map.Map SlotName.SlotName Binding -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> PlayerId -> TriggerCondition -> GameEvent -> Bool
matchesTriggerGiven bindings board gs bearer you cond event =
  anyTriggerReads event && armMatches bindings board gs bearer you cond event

-- The arm for this condition, which reads the event it watches and falls through
-- on the rest. Past anyTriggerReads, so only matchesTriggerGiven calls it.
armMatches :: Map.Map SlotName.SlotName Binding -> Map.Map ObjectId (BattlefieldCandidate.BattlefieldCandidate PC.ProjectedCharacteristics) -> GameState -> ObjectId -> PlayerId -> TriggerCondition -> GameEvent -> Bool
armMatches bindings board gs bearer you cond event = case cond of
  TriggerCondition.Enters t -> enters bearerContext board gs bearer you t event
  -- CR 603.2b: this step began, on a turn the scope admits, and -- for a card
  -- that counts main phases rather than naming one -- at CR 505.1b's ordinal.
  TriggerCondition.StepBegins (StepBegins.MkStepBegins wanted ordinal scope) -> case event of
    GameEvent.StepBegan (StepBegan.MkStepBegan began active) ->
      began == wanted
        && Maybe.maybe True (== mainPhasesBegun gs) ordinal
        && Turn.turnScopeAdmits scopeNamed gs scope active you
    _ -> False
  -- CR 603.8: a state trigger is not an event trigger. It never matches an entry
  -- in the log; stateTriggers below is its whole story.
  TriggerCondition.StateIs _ -> False
  -- CR 603.2 / 120.1: the watched permanent or spell dealt damage of the kind to
  -- a recipient the trigger admits, any recipient where it names none. Firing
  -- once per damage event and damager for that reading is `batchScoped`,
  -- `batchPartition` and eventTriggers' dedup, never this arm.
  --
  -- A player recipient's relation is read off the RECIPIENT against CR 109.5's
  -- `you`, the bearer's controller even when the damager is another permanent
  -- (Curiosity's ruling). It is not redundant with the attack: CR 614.9's
  -- redirection replaces the event's recipient and nothing else, so Harm's Way
  -- can turn an attacker's combat damage onto its own controller.
  -- Parun.FlipSpec's "CR 603.2 Harm's Way sends Akki's combat damage to alice,
  -- and Akki does not flip" proves the relation, and data/scenarios/event-trigger's
  -- "Teysa ignores combat damage dealt to another player" a bystander's.
  --
  -- A permanent recipient's card type is read off Projection.damagedCardTypes
  -- rather than a Recipient.ToCreature test: the tag is the classification made
  -- where the recipient was built, so an attacked permanent that is a
  -- planeswalker and a creature is still dealt damage as a creature, and the tag
  -- is unioned in, CR 608.2h's last known information for a recipient the damage
  -- killed.
  TriggerCondition.DealsDamage watched -> case event of
    GameEvent.DamageDealt ev ->
      damageBy (DamageTrigger.actor watched) (DamageEvent.source ev)
        && all (== DamageEvent.kind ev) (DamageTrigger.kind watched)
        && (Set.null (DamageTrigger.recipients watched) || any (damagedIs (DamageEvent.target ev)) (DamageTrigger.recipients watched))
    _ -> False
  -- CR 120.3: the watched permanent was DEALT damage -- enrage's event, and
  -- Death Pits of Rath's. DealsDamage's arm with the check moved from the
  -- event's SOURCE to its RECIPIENT.
  --
  -- The KIND conjunct is DealsDamage's: Nothing for Ripjaw
  -- Raptor's unqualified phrase, which a Prodigal Sorcerer's ping fires exactly
  -- as combat damage does; Just Combat for Wall of Essence's CR 510.2 damage.
  --
  -- Recipient.objectOf, not a ToCreature test: CR 120.3's recipient may be any
  -- permanent (a planeswalker, a battle), and the ActingPermanent decides the
  -- match either way. Nothing is dealt damage while the id is a player's, which
  -- is what the Nothing arm falls through on.
  TriggerCondition.IsDealtDamage (PermanentIsDealtDamage.MkPermanentIsDealtDamage (DealtDamage.MkDealtDamage watched kind) _) -> case event of
    GameEvent.DamageDealt ev ->
      all (== DamageEvent.kind ev) kind
        && maybe False (damageBy watched) (Recipient.objectOf (DamageEvent.target ev))
    _ -> False
  -- CR 120.3: a player the relation admits was DEALT damage, by any source and
  -- of the kind asked for -- the arm above with the recipient a player rather
  -- than the bearer. CR 120.2b's noncombat damage is every damage event that is
  -- not CR 510.2's, which DamageEvent.kind already records.
  --
  -- With orTheirPlaneswalkers, CR 120.3c's planeswalker recipient too
  -- (dealtToRelated).
  TriggerCondition.PlayerIsDealtDamage watched -> case event of
    GameEvent.DamageDealt ev ->
      let dealt = PlayerIsDealtDamage.dealt watched
       in all (== DamageEvent.kind ev) (DealtDamage.kind dealt)
            && dealtToRelated board gs (PlayerRelation.holds (Game.teams gs) (DealtDamage.recipient dealt) you) (PlayerIsDealtDamage.orTheirPlaneswalkers watched) (DamageEvent.target ev)
    _ -> False
  -- CR 725.2: a creature dealt combat damage to the monarch, who is "you" --
  -- the ability's controller (Event.Trigger.inherentTriggers). The damager is
  -- read off the event's sample, for combatDamagerOn's reason.
  TriggerCondition.CreatureDealtCombatDamageToMonarch -> case event of
    GameEvent.DamageDealt _ -> Maybe.isJust (combatDamagerOn board you event)
    _ -> False
  -- CR 726.2, the same reading one rule over, the holder being "you". Firing
  -- once per damagers' controller is `batchScoped` and `batchPartition`, never
  -- this arm.
  TriggerCondition.CreaturesDealtCombatDamageToInitiative -> case event of
    GameEvent.DamageDealt _ -> Maybe.isJust (combatDamagerOn board you event)
    _ -> False
  -- CR 726.2's third ability is controlled by the player who TOOK the
  -- initiative, so the taker is "you".
  TriggerCondition.PlayerTookInitiative -> case event of
    GameEvent.TookInitiative taker -> taker == you
    _ -> False
  -- CR 603.12: a reflexive matches no log entry at all. Its trigger event
  -- happened during the resolution that CREATED it, which CR 603.12's own
  -- exception makes a question about the entry's existence rather than about the
  -- log -- so Event.delayedPending fires it with no event and this answers False
  -- for every one, StateIs' posture.
  TriggerCondition.Reflexive -> False
  -- CR 702.94a: the bearer IS the card that was revealed, and the reveal was
  -- miracle's own. A Self Cycled discard's shape one rule over, cause and all
  -- -- and for the same reason: the same card shown by an ordinary reveal
  -- reaches the same log through the same funnel and must fire nothing. That is rule 702.94a's "THIS
  -- WAY", and CR 603.11 is what makes the two halves one ability.
  --
  -- The Ordinary arm is a REGRESSION FENCE rather than proven behaviour, and so
  -- is `revealedInHand`'s: the pool's ordinary hand reveals -- an activation cost
  -- paid from a hidden zone, and CR 614.1c's as-enters reveal (Rustic Clachan) --
  -- are on cards that carry no miracle, so no board tells the two readings apart
  -- and neither gate can be broken on its own while the other stands. Written
  -- because the rule says it.
  --
  -- The id in the event is the incarnation that reached the hand, which is the
  -- object the hand source offers as the bearer -- no CR 400.7 step separates
  -- them, since CR 701.20b moves nothing.
  --
  -- The FIRST-DRAW gate is NOT re-asked here. Rule 702.94a states it on the
  -- static half, so it decides whether the reveal happens at all
  -- (Event.offerMiracleReveal); a reveal that happened cannot have been the wrong
  -- draw, and re-reading GameState.drawsThisTurn at the scan would ask about the
  -- board one CR 117.5 boundary later.
  TriggerCondition.SelfRevealedForMiracle -> case event of
    GameEvent.Revealed (Revealed.MkRevealed _ oid (RevealCause.ForMiracle _) _) -> oid == bearer
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.Ordinary _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ (RevealCause.AsDrawnUnder _) _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.LeavingFaceDown _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.LeavingFaceDownComponent _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.FaceDownSpell _) -> False
    -- CR 702.94a: a miracle card is revealed, never merely looked at.
    GameEvent.Looked {} -> False
    _ -> False
  -- CR 607.2h: the reveal was the BEARER's own draw-time reveal, so another
  -- object's (a second Rowen's) and an ordinary reveal of the same card fire
  -- nothing; at the timing the condition states, if any (CR 121.8); and the
  -- card matches the printed quality, read off the hand it was revealed in (CR
  -- 701.20b moves nothing).
  TriggerCondition.RevealedThisWay (RevealedThisWay.MkRevealedThisWay f wanted) -> case event of
    GameEvent.Revealed (Revealed.MkRevealed _ card (RevealCause.AsDrawnUnder (DrawnUnder.MkDrawnUnder under timing)) _) ->
      under == bearer
        && maybe True (== timing) wanted
        && maybe False (\view -> Filter.matches bearerContext view f) (Projection.viewWithLastKnown card gs card)
    GameEvent.Revealed (Revealed.MkRevealed _ _ (RevealCause.ForMiracle _) _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.Ordinary _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.LeavingFaceDown _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.LeavingFaceDownComponent _) -> False
    GameEvent.Revealed (Revealed.MkRevealed _ _ RevealCause.FaceDownSpell _) -> False
    _ -> False
  -- CR 701.9a: a card was discarded, narrowed by the way. CR 702.29a makes
  -- cycling a discard, so AnyDiscard admits a cycle; it is one Discarded event,
  -- so CR 702.29d's "only once" holds by construction (TriggerSpec's "CR
  -- 702.29d cycling a card fires the discard trigger exactly once"). Cycled is
  -- rule 702.29c's "to pay an activation cost of a cycling ability": an ordinary
  -- discard of a card with cycling reaches the same funnel and fires nothing.
  -- ExiledForMadness is rule 702.35a's "this way", read off `Discarded.madness`
  -- rather than the destination, since Rest in Peace's row chosen over
  -- madness's under CR 616.1 exiles the card just the same.
  --
  -- Self compares the bearer with the CR 400.7 incarnation the event carries,
  -- which is the object the graveyard or exile scan offers. Discarder relates
  -- the discarding player to CR 109.5's "you" (CR 603.3a) through
  -- PlayerRelation.holds (an opponent is CR 102.3's player not on your team),
  -- leaves the bearer out (Megrim watches someone else's hand), and reads the
  -- Filter off the card with last known information once it has moved on. Batching is `batchScoped`'s, never this arm's.
  TriggerCondition.Discards (DiscardTrigger.MkDiscardTrigger subject way _) -> case event of
    GameEvent.Discarded (Discarded.MkDiscarded discarder card cause madness _) ->
      let admitsWay = case way of
            DiscardWay.AnyDiscard -> True
            DiscardWay.Cycled -> cause == DiscardCause.ToPayCyclingCost
            DiscardWay.ExiledForMadness -> Maybe.isJust madness
       in admitsWay && case subject of
            DiscardSubject.Self -> card == bearer
            DiscardSubject.Discarder (PlayerActsOn.MkPlayerActsOn relation f) ->
              PlayerRelation.holds (Game.teams gs) relation you discarder
                && maybe False (\view -> Filter.matches bearerContext view f) (Projection.viewWithLastKnown card gs card)
    _ -> False
  -- CR 121.1: a card was DRAWN, by a player the relation admits, and it was that
  -- player's `nth` draw of the turn. The ordinal comes off the event, which
  -- Event.drawCard stamped from GameState.drawsThisTurn as the draw happened;
  -- CR 109.5 fixes "you" as the ability's controller (CR 603.3a), and an
  -- opponent is every other player for the reason a Discarder discard gives.
  --
  -- The bearer is NOT part of the match, exactly as for a Discarder discard: Erudite
  -- Wizard is a creature watching a library, and the card drawn is nothing to do
  -- with it.
  --
  -- Equality on the ordinal, which is what makes "your second card" fire once in
  -- a turn with five draws; no ordinal fires on every draw, one event per card
  -- (CR 121.2).
  TriggerCondition.PlayerDrawsNthCard (PlayerDrawsNthCard.MkPlayerDrawsNthCard relation nth) -> case event of
    GameEvent.Drew (Drew.MkDrew drawer ordinal) ->
      maybe True (== ordinal) nth
        && PlayerRelation.holds (Game.teams gs) relation you drawer
    _ -> False
  -- CR 725.1: a player BECAME the monarch. Matched against the event the
  -- crowning records, so every route through CR 725.1's "an effect instructs a
  -- player to become the monarch" fires it alike: Effect.BecomeMonarch records
  -- this event whichever MonarchTarget named the player, which covers an entry
  -- trigger's crown, a targeted crown and CR 725.2's stolen crown.
  --
  -- CR 725.4's departure reassignment records the same event, so the crown
  -- moving because the monarch left is matched alike. TriggerSpec's "CR 725.4 a
  -- departure crowns alice, and that crowning fires her edict" proves it.
  --
  -- The event carries exactly one player, which is CR 725.3 ("Only one player can
  -- be the monarch at a time") rather than a simplification -- so the relation is
  -- the whole comparison and there is no filter to apply. The bearer is NOT part
  -- of the match: Custodi Lich watches a designation, not itself.
  TriggerCondition.PlayerBecomesMonarch relation -> case event of
    GameEvent.BecameMonarch crowned -> PlayerRelation.holds (Game.teams gs) relation you crowned
    _ -> False
  -- CR 508.3, as a function of Parun.Types.AttackTrigger's arity and fields:
  -- attacks.
  TriggerCondition.Attacks t -> attacks bearerContext board gs bearer you t event
  -- CR 509.3, as a function of Parun.Types.BlockTrigger's fields: blocks.
  TriggerCondition.Blocks t -> blocks bearerContext board gs t event
  TriggerCondition.Leaves t -> leaves bindings bearerContext gs bearer you t event
  TriggerCondition.LeavesZone t -> leavesZone board gs bearer you (admitsTurn . LeavesZoneTrigger.scope) t event
  TriggerCondition.PutIntoZone t -> putIntoZone bearerContext board gs bearer you (admitsTurn . PutIntoZoneTrigger.scope) t event
  -- CR 603.2c's batch reading of DealsDamage's combat damage to a player (Pia Nalaar,
  -- Chief Mechanic's "whenever ONE OR MORE artifact creatures you control deal
  -- combat damage to a player"), delegated because which
  -- damage events this condition admits is the singular arm's answer, filter,
  -- kind and recipient alike (Norn's Decree's "deal combat damage to YOU"),
  -- and firing once for the CR 510.2 step is `batchScoped` below plus
  -- eventTriggers' dedup, never this arm.
  TriggerCondition.PermanentsDealCombatDamageToPlayer p ->
    matchesTriggerGiven
      bindings
      board
      gs
      bearer
      you
      ( TriggerCondition.DealsDamage
          DamageTrigger.MkDamageTrigger
            { DamageTrigger.actor = ActingPermanent.Matching (PermanentsDealCombatDamageToPlayer.filter p),
              DamageTrigger.kind = Just DamageKind.Combat,
              DamageTrigger.recipients = Set.singleton (DamageRecipient.Player (PermanentsDealCombatDamageToPlayer.recipient p))
            }
      )
      event
  -- CR 701.26a's tap, once per permanent: the bearer by id (City of Brass), or
  -- a permanent the Filter admits, judged off CR 603.10's board just after the
  -- event (Thoughtleech). Betrayal's "enchanted creature" is
  -- `Matching (HasAttached IsSource)`: the tapped host is still standing, so
  -- Projection.sampledView reads the attachment link off the sample rather than
  -- through last known information, where Leaves' Attached has to look
  -- back because the SBA batch that kills the host takes the link away (CR
  -- 704.5m).
  --
  -- CR 701.26b's untap is the same arm in the other direction: the bearer
  -- itself (Oreskos Sun Guide) or any permanent the Filter admits (Mesmeric
  -- Orb), each permanent CR 502.3 untaps its own event.
  --
  -- CR 603.2e's exclusions are discharged where the event is MINTED, in
  -- Parun.Engine.Event's `tap` and `untap` and Parun.Engine.Engine.untapAll,
  -- rather than here: a
  -- permanent that entered tapped or untapped never transitioned, and rules
  -- 701.26a and 701.26b make a repeat tap or untap no event at all. So this arm
  -- asks only whose transition it was.
  TriggerCondition.BecomesTapState watched ->
    let watches oid = case BecomesTapState.actor watched of
          ActingPermanent.Self -> oid == bearer
          ActingPermanent.Matching f -> case Map.lookup oid board of
            Nothing -> False
            Just candidate -> Filter.matches bearerContext (Projection.sampledView board oid candidate gs) f
     in case event of
          GameEvent.BecameTapped tapped -> BecomesTapState.status watched == TapState.Tapped && watches tapped
          GameEvent.BecameUntapped untapped -> BecomesTapState.status watched == TapState.Untapped && watches untapped
          -- CR 106.12a's event is a DIFFERENT one, and stated rather than folded
          -- into the arm above: a mana activation writes both, and matching this
          -- one here would fire Betrayal twice off one tap.
          GameEvent.TappedForMana _ -> False
          _ -> False
  -- CR 701.26a's batch reading by a bystander, the arm above's match; firing
  -- once for a batch is `batchScoped` plus eventTriggers' dedup, never this arm.
  TriggerCondition.PermanentsBecomeTapped f -> matchesTriggerGiven bindings board gs bearer you (TriggerCondition.BecomesTapState (BecomesTapState.MkBecomesTapState TapState.Tapped (ActingPermanent.Matching f))) event
  TriggerCondition.AttachedPermanentTappedForMana -> case event of
    GameEvent.TappedForMana tapped ->
      Game.hostOf bearer gs == Just (TappedForMana.permanent tapped)
    _ -> False
  -- CR 106.12a read by a BYSTANDER, where the arm above reads it off an
  -- attachment link: Autumn Willow, Harmony's "whenever you tap a land creature
  -- for mana". Every part of the printed sentence is compared, the
  -- PermanentSacrificed arm's posture -- the tapping player against CR 109.5's
  -- `you`, the permanent against the Filter, and the mana produced against that
  -- rule's "of a specified type" (producedSpecified) -- and a wording that
  -- narrows none of them spells itself out as AnyPlayer over the trivial Filter
  -- with ManaSpecification.AnyMana.
  --
  -- The TAPPING player is the event's own, the mana ability's controller (CR
  -- 113.8), not the permanent's: Piracy lets a player tap lands they don't
  -- control. Parun.ScenarioSpec's "CR 106.12a alice taps bob's Dryad Arbor
  -- under Piracy" proves both seats.
  --
  -- LIVE, the arm above's reason and not the PermanentSacrificed arm's: nothing
  -- has moved, and Parun.Engine.Cost.applyManaTriggers records this event with
  -- the permanent standing tapped on the battlefield. viewWithLastKnown all the
  -- same, so a permanent that left between the tap and the gather is answered
  -- for rather than silently missed.
  -- CR 605.1b's first alternative read off the bearer's own mana ability:
  -- Tyvar the Bellicose's "whenever a mana ability of this creature
  -- resolves". Self-scoped, so the whole match is an id comparison -- CR
  -- 605.3b leaves the ability no object, and Parun.Engine.Cost.tapForManaWith
  -- records the permanent that stood in for it.
  --
  -- NO projection read beside it, where the PermanentTappedForMana arm below
  -- takes one: the condition carries no Filter and no relation, so there is
  -- nothing to ask a view about.
  TriggerCondition.SelfManaAbilityResolves -> case event of
    GameEvent.ManaAbilityResolved resolved -> ManaAbilityResolved.permanent resolved == bearer
    _ -> False
  TriggerCondition.PermanentTappedForMana (PermanentTappedForMana.MkPermanentTappedForMana relation f specified) -> case event of
    GameEvent.TappedForMana tapped
      | PlayerRelation.holds (Game.teams gs) relation you (TappedForMana.player tapped) && producedSpecified gs bearer specified (TappedForMana.mana tapped) ->
          case Projection.viewWithLastKnown (TappedForMana.permanent tapped) gs (TappedForMana.permanent tapped) of
            Nothing -> False
            Just view -> Filter.matches bearerContext view f
      | otherwise -> False
    _ -> False
  -- CR 605.1b's "mana being added to a player's mana pool", read by a
  -- bystander: Caged Sun's "whenever a land's ability causes you to add one or
  -- more mana of the chosen color". The PermanentTappedForMana arm's posture --
  -- the adding player against `you` under the relation, the ability's source
  -- against the Filter, the added mana against the specification -- except
  -- that the player is the event's own recipient rather than a controller read
  -- off the board: CR 106.4 names whose pool the mana went to.
  TriggerCondition.AbilityAddsMana (AbilityAddsMana.MkAbilityAddsMana relation f specified) -> case event of
    GameEvent.ManaAdded added
      | PlayerRelation.holds (Game.teams gs) relation you (ManaAdded.player added) && producedSpecified gs bearer specified (ManaAdded.mana added) ->
          case Projection.viewWithLastKnown (ManaAdded.source added) gs (ManaAdded.source added) of
            Nothing -> False
            Just view -> Filter.matches bearerContext view f
      | otherwise -> False
    _ -> False
  -- CR 701.6a: a spell was countered, by a spell or ability whose controller the
  -- relation admits. The countering source's controller comes from the event,
  -- captured as the counter happened, and CR 109.5/603.3a fix "you" as the
  -- ability's controller.
  --
  -- The bearer is NOT part of the match -- the Discarder discard's posture rather than
  -- any Self- condition's -- since the bearer is a permanent and the countering is
  -- done by a spell somewhere else.
  --
  -- Neither "can't be countered" gate needs a clause here -- CR 113.6g's on the
  -- spell, CR 613.11's on a permanent's static ability: a spell that can't be
  -- countered is not countered at all (CR 101.2), so `counter` records nothing
  -- and there is no event for this arm to see.
  TriggerCondition.SpellOrAbilityCounters relation -> case event of
    GameEvent.SpellCountered c -> PlayerRelation.holds (Game.teams gs) relation you (Countering.controller c)
    -- CR 701.6a's other subject, and the fence Baral needs: his sentence says
    -- "counters A SPELL", so a countered ABILITY is not his event.
    GameEvent.AbilityCountered _ -> False
    _ -> False
  -- CR 701.6a from the VICTIM's side: an ability was countered, whoever did it.
  -- The event alone settles it -- the arm above's relation has no counterpart
  -- here, the printed sentence this serves naming no player at all -- so the
  -- constructor IS the match.
  --
  -- A countered SPELL is silence rather than a miss, which is the whole point of
  -- the two arms: CR 701.6a cancels a spell and an ability by different means,
  -- and Baral, Chief of Compliance reads the other one.
  --
  -- The bearer is not part of the match, SpellOrAbilityCounters' posture: the
  -- bearer is a permanent and the countering happens somewhere else. Neither
  -- "can't be countered" gate needs a clause, for that arm's reason: through CR
  -- 101.2 nothing was countered, so `counter` records no event to see.
  TriggerCondition.AbilityIsCountered -> case event of
    GameEvent.AbilityCountered _ -> True
    _ -> False
  -- CR 615.13: a prevention effect was applied and prevented some damage, and the
  -- damage it prevented was addressed to a player the relation admits. CR 109.5 /
  -- 603.3a fix "you" as the ability's controller, exactly as a Discarder discard and
  -- SpellOrAbilityCounters do.
  --
  -- The bearer is NOT part of the match: Selfless Squire is a creature watching
  -- damage addressed to its controller, and CR 615.13 says nothing about which
  -- object the ability is on.
  --
  -- ONE fire per recorded event, and the record is already grouped per prevention
  -- effect per batch (Replacement.groupPreventions), which is where CR 615.13's
  -- "one or more simultaneous damage events" is honoured. Nothing here has to
  -- count.
  --
  -- Damage prevented to a PERMANENT is silence rather than a miss: the printed
  -- sentence says "to you", and the recipients the event carries are what
  -- distinguishes the two. One record can hold BOTH, a shield covering a player
  -- and their permanents being one application (Divine Deflection), so the match
  -- is over the map's player entries rather than over a single recipient.
  --
  -- ABOVE 0, which is CR 615.12's case one recipient at a time: an application
  -- that was inert against the damage aimed at this player prevented none of it,
  -- however much of the same batch it stopped elsewhere, and rule 615.13 fires
  -- only where some was prevented.
  TriggerCondition.DamageToPlayerPrevented relation -> case event of
    GameEvent.DamagePrevented prevented ->
      let admits (recipient, amount) =
            amount > 0 && case recipient of
              Recipient.ToPlayer pid -> PlayerRelation.holds (Game.teams gs) relation you pid
              Recipient.ToCreature _ -> False
              Recipient.ToPlaneswalker _ -> False
              Recipient.ToBattle _ -> False
              Recipient.ToObject _ -> False
              -- Unreachable: CR 406.4's pile is a candidate at CR 601.2c and
              -- never something damage is dealt to.
              Recipient.ToPile _ -> False
       in any (any admits . Map.toList) (DamagePrevented.amounts prevented)
    _ -> False
  -- CR 615.13's other reading: the damage was prevented THIS WAY -- by a
  -- prevention effect the BEARER's own card prints (Phyrexian Vindicator).
  -- Replacement.printedBy is that question, and it plus the Filter below is the
  -- whole of the match: rule 615.13 says nothing about whom the damage was
  -- addressed to, and neither does either printed sentence.
  --
  -- The identity, never the recipient: the Vindicator's shield covers only
  -- itself, so a recipient test would be a second name for a fact the identity
  -- already settles -- and one prevention effect of another object covering the
  -- SAME recipient is exactly the case this arm has to answer False for.
  --
  -- The Filter is over CR 120.1's SOURCES of the damage that did not happen --
  -- Samite Ministration's "damage from a black or red source" -- and fires ONCE
  -- if it admits any of them (Event.Binding.admittedPreventedSources), one
  -- application being one CR 615.13 trigger however many sources it covered.
  -- The bearer contributes only CR 109.5's "you" and the Filter.Context's
  -- source, as in the DealsDamage arm above. viewWithLastKnown:
  -- CR 608.2h's record is what still answers "was it a creature" for a source
  -- gone by now. Proved by judgment-of-alexander-fires-for-a-sacrificed-creature.
  --
  -- Filter.IsSource is meaningless in THIS position where it is meaningful
  -- there: the context's source is the bearer, and the bearer is the object whose
  -- prevention effect applied, never the object that would have dealt the damage.
  TriggerCondition.SelfPreventsDamage f -> case event of
    GameEvent.DamagePrevented prevented ->
      Replacement.printedBy (DamagePrevented.by prevented) == Just bearer
        && not (Map.null (admittedPreventedSources bearerContext gs f prevented))
    _ -> False
  -- CR 119.3 / 119.9: a player the relation admits gained or lost life, on a
  -- turn the scope admits. The changing player comes off the event, and CR 109.5
  -- / 603.3a fix "you" as the ability's controller; the bearer is not part of the
  -- match. The relation is read as of the event (CR 603.2), so an opponent the
  -- loss knocked out of the game still counts (Parun.SpeedSpec's "CR 603.2 an
  -- opponent the loss knocked out still raises your speed").
  --
  -- No zero check: CR 119.9's "no life gain event" is enforced where each event
  -- is recorded, so a logged change is more than 0. A gain and a loss are
  -- different events (one lifelink hit records both), never a signed change.
  -- The first-time reading is stamped on the event as it happened
  -- (Event.lifeChanged). Batching is not read here: batchScoped and
  -- eventTriggers' dedup are what separate "a player" from "one or more".
  TriggerCondition.LifeChanges (LifeTrigger.MkLifeTrigger direction relation scope _ frequency) ->
    let admits (LifeChange.MkLifeChange pid _ first) =
          PlayerRelation.holds (Game.teams gs) relation you pid
            && Turn.turnScopeAdmits scopeNamed gs scope (GameState.activePlayer gs) you
            && case frequency of
              TriggerFrequency.EveryTime -> True
              TriggerFrequency.FirstTimeEachTurn -> first
     in case (direction, event) of
          (LifeDirection.Gained, GameEvent.LifeGained change) -> admits change
          (LifeDirection.Lost, GameEvent.LifeLost change) -> admits change
          _ -> False
  -- CR 603.2 / 122.6: counters of the kind moved the trigger's way on the
  -- holder. The bearer by id, or a permanent the Filter admits, read through
  -- viewWithLastKnown (CR 608.2h) so the CR 704.5f victim a -1/-1 counter made
  -- still matches; the bearer frames that match as the Filter.Context's source.
  --
  -- No "one or more" conjunct: each counter record exists only where its count
  -- changed, and settleCounters records one per settled placement. How many
  -- triggers one match makes is the grouping's, read by
  -- Parun.Engine.Event.Trigger's `batchScoped` and `counterOccurrences`, never
  -- by this matcher (CR 603.2c).
  --
  -- A threshold crosses the way the counters moved. Going on it is CR 714.2b's
  -- "was less than N and became at least N", `n <= after` rather than equality
  -- because one placement can cross several chapters; read ahead (CR 702.155a)
  -- narrows it to equality on the turn the Saga entered, through
  -- Saga.chapterTriggers, which gates on Keyword.ReadAhead and so is inert for
  -- every other permanent. A removal crosses nothing going up, so a Saga whose
  -- lore counters were taken off and put back fires its chapters again. Coming
  -- off it is CR 310.12b's last counter at N = 0. The projection is lazy and
  -- asked after `after == n`, so it is forced only where the readings differ.
  TriggerCondition.CountersChange counterTrigger -> case countersMoved gs you counterTrigger event of
    Nothing -> False
    Just (oid, before, after) ->
      ( case CounterTrigger.holder counterTrigger of
          CounterHolder.Self -> oid == bearer
          CounterHolder.Permanent f -> maybe False (\view -> Filter.matches bearerContext view f) (Projection.viewWithLastKnown oid gs oid)
      )
        && case (CounterTrigger.motion counterTrigger, CounterTrigger.threshold counterTrigger) of
          (_, Nothing) -> True
          (CounterMotion.Put _, Just n) -> Saga.chapterTriggers (Saga.readAheadRestricted (Projection.project oid gs) gs oid) before after n
          (CounterMotion.Removed, Just n) -> after <= n && n < before
  -- CR 716.2a: the BEARER's class level crossed N going up. "When this Class
  -- becomes level N" is printed inside the level-N section, so CR 716.2a's static
  -- half is what grants it, and CR 603.10 is what lets it see its own arrival:
  -- "becomes level N" is not on that rule's exhaustive look-back list, so the
  -- abilities checked are the ones existing immediately AFTER the level changed.
  --
  -- `before < n` is what stops a later bar re-firing an earlier section's
  -- trigger: a Class going from level 2 to level 3 crosses 3 and nothing else.
  --
  -- `n <= after` rather than `n == after`, CountersChange's reading of the
  -- same shape: one write can cross several thresholds, so a Class set straight
  -- from level 1 to level 3 fires both sections' triggers. No level bar can do
  -- that (CR 716.2a's "only if this Class is level N-1"), which is why the two
  -- readings coincide for every printing in `data/cards/` -- Effect.SetClassLevel
  -- is an opcode, not a bar, and this is the reading the rule states.
  --
  -- Saga.crossed says the same sentence for lore counters and is deliberately not
  -- reused: it is over Naturals, and its haddock ties it to CR 714.2b and to the
  -- agreement CR 704.5s's state-based action needs with it. A class level is a
  -- ClassLevel and has no state-based action to agree with.
  TriggerCondition.SelfBecomesClassLevel n -> case event of
    GameEvent.ClassLevelSet (ClassLevelChange.MkClassLevelChange oid before after) -> oid == bearer && before < n && n <= after
    _ -> False
  -- CR 601.2i's "any abilities that trigger when a spell is cast": a spell the
  -- Filter admits became cast. The bearer frames the match rather than being it,
  -- as for a Matching Enters -- it is the Filter.Context's source, and its
  -- controller is the perspective CR 109.5 gives "you" in "whenever YOU CAST an
  -- instant or sorcery spell".
  --
  -- The CASTER comes from the event and is handed to the view as the spell's
  -- controller, which is what makes Filter.HeldBy Holder.Controller You answer the printed
  -- "you". Not read off the object: Event.changeZone stamps Object.enteredUnder
  -- only for a battlefield entry, so a stack object falls back to its OWNER
  -- (Projection.defaultControllerOf) -- the same player for every cast in the
  -- pool today, and the wrong one the moment a card lets somebody cast a card
  -- they do not own. CR 601.2a settles it the other way: the player casting the
  -- spell is its controller.
  --
  -- The spell is read LIVE off the stack rather than from a snapshot, which is
  -- what separates this arm from Leaves'. CR 601.2i's trigger event is
  -- the spell BECOMING cast, and CR 601.2a leaves it on the stack "until it
  -- resolves, it's countered, or a rule or effect moves it elsewhere" -- none of
  -- which can have happened before the scan, since the cast is the last thing
  -- Cast.castSpell does. So no CR 608.2h fallback is reachable, and the `Nothing`
  -- below is the id naming nothing at all, about which no Filter can honestly
  -- answer.
  --
  -- The TurnScope is the second half, and it comes from the GAME STATE rather
  -- than from the event: GameEvent.SpellCast records the caster and the spell,
  -- never the turn, and CR 601.2i's trigger is checked in the same settle the
  -- cast happened in -- so the active player standing now is the one the cast
  -- happened under. Read against `you`, CR 109.5's controller of the ability (CR
  -- 603.3a), exactly as the StepBegins arm above reads its own.
  --
  -- A Self subject is "when you cast this spell" (Desolation Twin): the spell
  -- that became cast IS the bearer, a bare comparison of ids and no Filter at
  -- all, so nothing about the spell is read and no CR 608.2h fallback is
  -- reachable. The bearer is the STACK object, which is the same id
  -- GameEvent.SpellCast carries: CR 601.2a puts the card on the stack as it is
  -- cast and leaves it there, so eventTriggers' `spellCast` source offers
  -- exactly that incarnation. Its scope is EachTurn (CR 601.2i says nothing
  -- about whose turn it is, and no printing narrows its own cast by one), and a
  -- spell's own cast is the first of its kind, so its ordinal is one.
  TriggerCondition.SpellCast (SpellCast.MkSpellCast subject scope fromZone ordinal window copies) ->
    let -- What a cast and a copy are both asked: whose turn, which phase, and
        -- which spell -- the bearer, or one the Filter admits as its
        -- controller sees it.
        admits controller spell =
          Turn.turnScopeAdmits scopeNamed gs scope (GameState.activePlayer gs) you
            -- "During combat" off the GAME STATE, the TurnScope's reason: the
            -- event happened in this same settle, so the phase standing now is
            -- its phase.
            && maybe True (`Turn.inWindow` GameState.phase gs) window
            && case subject of
              ActingPermanent.Self -> spell == bearer
              ActingPermanent.Matching f -> Filter.matches bearerContext (Projection.viewOfSpell controller spell gs) f
        ordinalOf caster spell = case subject of
          ActingPermanent.Self -> Just 1
          ActingPermanent.Matching f -> castOrdinal bearerContext f fromZone caster spell gs
     in case event of
          GameEvent.SpellCast (SpellWasCast.MkSpellWasCast caster spell _ castFrom _ _) -> case Game.lookupObject spell gs of
            Nothing -> False
            Just _ ->
              admits caster spell
                -- CR 601.2a's zone, read off the EVENT and not off the spell: rule
                -- 400.7 left the stack incarnation with no memory of it. A
                -- condition that names no zone admits every cast, which is what
                -- almost every printing writes.
                && maybe True (\z -> castFrom == Just z) fromZone
                -- Clarion Spirit's "your SECOND spell each turn", asked LAST so the
                -- log walk happens only for a cast the rest of the condition
                -- already admits.
                && maybe True ((ordinalOf caster spell ==) . Just) ordinal
          -- Magecraft's "or copy" (CR 707.10): the player who copied the spell,
          -- the copy's controller, is the one whose "you copy" this is -- not
          -- the copied spell's. data/scenarios/copy's
          -- Twincast-and-magecraft case proves it. A copy left no zone and is
          -- no cast of the turn, so a zone or an ordinal never admits it.
          GameEvent.SpellCopied (SpellWasCopied.MkSpellWasCopied copier copy) ->
            copies
              && Maybe.isNothing fromZone
              && Maybe.isNothing ordinal
              && Maybe.isJust (Game.lookupObject copy gs)
              && admits copier copy
          _ -> False
  -- CR 602.2b / 601.2i: the Filter over the ability on the stack, its
  -- controller the activator (CR 602.2a), read live for SpellCast's reason --
  -- the activation is the last thing Activate.activateAbilityWith does, so the
  -- ability is still on the stack -- and its source through CR 113.7a's last
  -- known information (Filter.FromSource), so a source sacrificed to pay the
  -- cost still answers.
  TriggerCondition.AbilityActivated f -> case event of
    GameEvent.AbilityActivated activated ->
      Maybe.isJust (Game.lookupObject (AbilityWasActivated.ability activated) gs)
        && Filter.matches bearerContext (Projection.viewOfSpell (AbilityWasActivated.player activated) (AbilityWasActivated.ability activated) gs) f
    _ -> False
  -- CR 601.2c from the PLAYER's side, BecomesTargeted's Self subject one
  -- recipient over: Dormant Gomazoa's "whenever you become the target of a
  -- spell" and Amulet of Safekeeping's "whenever you become the target of a spell or ability an
  -- opponent controls". The recipient is compared with CR 109.5's "you" -- CR
  -- 603.3a's controller of the bearer as the ability triggered -- rather than
  -- with the bearer, which is the whole of what separates this from ward.
  --
  -- The KIND conjunct is the arm's rules content, and it is a Maybe: CR 112.1
  -- makes a spell a card on the stack, while CR 602.2b and CR 603.3d route an
  -- activated and a triggered ability through the same rule 601.2c. Gomazoa names
  -- Spell and Ravenous Rats' targeted discard must not untap it; Amulet names
  -- neither limb and takes both.
  --
  -- The RELATION is ward's, read off the same BecameTarget.controller field --
  -- CR 405.4's controller of the targeting object, which is who Amulet offers the
  -- {1} to. Gomazoa's AnyPlayer fires on its own spells as readily as on an
  -- opponent's.
  TriggerCondition.ControllerBecomesTarget c -> case event of
    GameEvent.BecameTarget t ->
      Recipient.playerOf (BecameTarget.targeted t) == Just you
        && maybe True (== BecameTarget.kind t) (ControllerBecomesTarget.kind c)
        && PlayerRelation.holds (Game.teams gs) (ControllerBecomesTarget.relation c) you (BecameTarget.controller t)
    _ -> False
  -- CR 601.2c / 603.2c: a permanent became the target of a spell or ability. A
  -- Self subject is the bearer, a bare comparison of ids in a Self SpellCast's
  -- shape and for its reason -- nothing about the targeting spell is read, so
  -- no projection can come up empty.
  --
  -- The RELATION is read off the event's own controller field rather than off the
  -- board, which is what CR 405.4 asks for: the answer wanted is who controlled
  -- the targeting object as it was announced, and by the time a ward trigger is
  -- gathered that object may already have changed hands or left.
  --
  -- Rule 702.21a's own relation is Opponent; You is admitted because the
  -- condition is stated over a PlayerRelation, and a card printing the other half
  -- would read the same field. The kind and the relation are read the same way
  -- under either subject.
  --
  -- A Matching subject is the same rule from a BYSTANDER's side: Professor Hojo
  -- asks nothing of the targeting object's controller and everything of the
  -- permanents it named, and Diffusion Sliver asks both; the relation is read
  -- off the event's controller field for the Self subject's CR 405.4 reason.
  --
  -- The KIND conjunct is ControllerBecomesTarget's one limb narrower. "An
  -- ACTIVATED ability" is CR 113.3b alone, where CR 603.3d brings CR 113.3c's to
  -- the same rule 601.2c step, so a condition that did not ask would draw off a
  -- triggered ability too. Parun.LeavesTriggerSpec's activated-against-triggered pair is
  -- what proves it.
  --
  -- CR 109.2 scopes the Filter to the BATTLEFIELD, which is the arm's other
  -- rules content and belongs here rather than in each card's Filter: a target
  -- is any Recipient, so a creature SPELL on the stack its controller named
  -- would otherwise satisfy "creatures you control".
  --
  -- Membership and view both off `board`, CR 603.10's sample of the
  -- announcement (Event.becameTarget takes it before any cost is paid), not the
  -- board at the CR 117.5 gather: a permanent named as a target and sacrificed
  -- to pay for it was a target while it stood. Parun.LeavesTriggerSpec's
  -- "Professor Hojo sees a target its own cost sacrificed" proves it.
  --
  -- Firing ONCE for the whole announcement under OneOrMore is
  -- Event.Trigger.batchScoped's answer and not this function's:
  -- matchesTriggerGiven sees one event at a time and answers the same for both
  -- batchings, which is its contract.
  --
  -- With includesYou, CR 109.5's "you" named as a target is a member too, the
  -- ControllerBecomesTarget arm's test: Leyline of Combustion's "you and/or at
  -- least one permanent you control".
  TriggerCondition.BecomesTargeted c -> case event of
    GameEvent.BecameTarget t ->
      maybe True (== BecameTarget.kind t) (BecomesTargetedTrigger.kind c)
        && PlayerRelation.holds (Game.teams gs) (BecomesTargetedTrigger.relation c) you (BecameTarget.controller t)
        && case (Recipient.playerOf (BecameTarget.targeted t), Recipient.objectOf (BecameTarget.targeted t)) of
          (Just player, _) -> BecomesTargetedTrigger.includesYou c && player == you
          (Nothing, Nothing) -> False
          (Nothing, Just oid) -> case BecomesTargetedTrigger.permanent c of
            ActingPermanent.Self -> oid == bearer
            ActingPermanent.Matching f -> case Map.lookup oid board of
              Nothing -> False
              Just candidate -> Filter.matches bearerContext (Projection.sampledView board oid candidate gs) f
    _ -> False
  -- CR 709.5h: the bearer is the permanent that was given the designation, and
  -- the door named is the one it was given for. A bare comparison of an id and a
  -- name, in a Self Enters' shape and for its reason -- nothing about the entrant's
  -- characteristics is read, so there is no CR 608.2h fallback to reach for.
  --
  -- The half is checked as well as the bearer, which is the arm's whole content:
  -- CR 709.5h fires "when a player unlocks a PARTICULAR half", so a Room whose
  -- other door was the one that opened must not fire this ability.
  TriggerCondition.SelfHalfUnlocked half -> case event of
    GameEvent.HalfUnlocked (HalfUnlocked.MkHalfUnlocked oid _ name _) -> oid == bearer && name == half
    _ -> False
  -- CR 708.7 through CR 603.2: a Self subject is the permanent that turned over.
  -- A Self Enters' shape -- a bare comparison of ids, with nothing about the
  -- permanent's characteristics read, so no CR 608.2h fallback is reachable.
  --
  -- The BEARER check is what keeps one player's face-up Skirk Marauder from
  -- firing off a different permanent turning over; Parun.FaceDownSpec seats a
  -- second face-down permanent on the same board to prove it.
  --
  -- Nothing here asks whether the permanent had ALREADY entered the battlefield.
  -- CR 708.7 leaves turning face up something only a permanent can be doing, and
  -- Event.performTurnFaceUp is the sole writer of this event -- CR 708.3's
  -- face-down ENTRY writes a Moved event and never this one, which is what makes
  -- CR 708.8's last sentence fall out rather than needing a clause.
  --
  -- A Matching subject is the other written form, read by a bystander:
  -- "whenever a permanent is turned face up". Matching Enters' shape against
  -- Self Enters', and for its reason -- the bearer frames the match rather than
  -- being it. The bearer is the Filter.Context's source (so `Not IsSource` would
  -- be an "another"), and its controller is the perspective CR 109.5 gives "you"
  -- in Deathmist Raptor's "a permanent YOU CONTROL is turned face up".
  --
  -- NO comparison against the bearer at all, which is the whole difference from
  -- the Self subject: Aven Farseer bears no morph ability and so can never be the
  -- permanent that turned over, and a bearer check here would make its ability
  -- dead text. Parun.FaceDownSpec's "a permanent turning face up puts Aven
  -- Farseer's counter on the FARSEER" is what proves the scope, asserting the
  -- counter's landing place by object id on a board where the watcher and the
  -- subject are two permanents.
  --
  -- Read LIVE off the game as it stands, like a Matching Enters and unlike
  -- Leaves: CR 708.8 leaves the permanent on the battlefield with its
  -- normal copiable values restored, so there is nothing for CR 603.10a's
  -- look-back to recover and the live read is what CR 603.10's first sentence
  -- asks for. It is also the only read that can answer a narrowed form correctly
  -- -- CR 708.2 gives a face-down permanent only the characteristics its listing
  -- names and never the card's, so a Filter applied to the pre-turning object
  -- would decline every "a Dragon is turned face up" there is.
  --
  -- viewWithLastKnown rather than viewOfObject: a permanent turned face up and
  -- gone again before the CR 117.5 boundary is still read as it was on the
  -- battlefield (CR 608.2h) instead of vanishing from the match. Nothing is a permanent that is gone AND filed no last known
  -- information, about which no Filter can honestly answer.
  TriggerCondition.TurnedFaceUp subject -> case event of
    GameEvent.TurnedFaceUp t -> case subject of
      ActingPermanent.Self -> TurnedFaceUp.object t == bearer
      ActingPermanent.Matching f -> case Projection.viewWithLastKnown (TurnedFaceUp.object t) gs (TurnedFaceUp.object t) of
        Nothing -> False
        Just view -> Filter.matches bearerContext view f
    _ -> False
  -- CR 701.27e through CR 603.2: a Self subject is the permanent that
  -- transformed, and the names the event carries are what it turned INTO, which
  -- `into` asks for when it names a face. TurnedFaceUp's Self subject above is
  -- the neighbouring shape, plus the name -- and CR 701.27b is why they are two
  -- conditions rather than one, turning over and turning face up being
  -- different game actions.
  --
  -- Both halves are read off the EVENT, neither off the board. The board at the
  -- CR 117.5 scan is not the board CR 701.27e asks about: a permanent that
  -- transformed twice before the scan shows only its last face, which would
  -- answer this arm wrong on both events. Parun.Types.Transformed carries the
  -- sample for that reason.
  --
  -- Set.member rather than equality because CR 709.4a admits several names and
  -- CR 708.2a admits none; a permanent with no name matches no named face,
  -- which is the rule's own answer rather than a guard.
  --
  -- A Matching subject is CR 701.27e's OTHER written form, read by a bystander:
  -- "whenever a permanent you control transforms into a non-Human creature" (Cult
  -- of the Waxing Moon).
  -- TurnedFaceUp's Matching shape against its Self one, one rule along --
  -- the bearer frames the match rather than being it, contributing CR 109.5's
  -- perspective and the Filter.Context's source and nothing else.
  --
  -- The CHARACTERISTICS come off the event and everything else off the board,
  -- which is what Count.overlaySnapshot is for: CR 701.27e pins the specified
  -- characteristic to the instant the turn finished, and a wholly live read
  -- would answer wrong for a permanent that turned twice before the CR 117.5
  -- scan, which is the argument Parun.Types.Transformed makes for carrying the
  -- sample.
  --
  -- The CONTROLLER and the ATTACHMENTS come off the event too, and for CR
  -- 603.10's reason rather than CR 701.27e's: that rule pins the whole appearance
  -- of the objects to immediately after the event, and CR 109.3 keeps both axes
  -- out of an object's characteristics, so neither can ride the snapshot. The
  -- board this arm is handed has had state-based actions run over it (CR 117.5),
  -- and CR 704.5n is the one that moves -- an Equipment on a permanent that just
  -- turned into a noncreature has already fallen off. Proved by
  -- Parun.TransformSpec's "CR 603.10 / 704.5n the Heirloom turns over though the
  -- unattach beat the scan".
  --
  -- The controller is written over the LIVE view before the snapshot is folded in
  -- rather than after, so Count.viewOfSnapshot derives its half against the same
  -- player CR 603.3a will read. Nothing in data/cards/ tells the two readings
  -- apart -- the control axis is a regression fence here, not a proved behaviour.
  --
  -- Each attacher's own appearance is rebuilt from the board at the scan: the
  -- event carries their ids, which is what CR 603.10's "objects involved in the
  -- event" needs for a HasAttached, and viewWithLastKnownAnywhere so an attacher
  -- that has since left is still read (CR 608.2h).
  --
  -- viewWithLastKnown rather than viewOfObject, a Matching TurnedFaceUp's reason:
  -- a permanent that turned over and left before the CR 117.5 boundary is still
  -- read as it was on the battlefield (CR 608.2h).
  TriggerCondition.Transforms (TransformTrigger.MkTransformTrigger subject into) -> case event of
    GameEvent.Transformed transformed ->
      maybe True (\name -> Set.member name (PC.names (Transformed.characteristics transformed))) into && case subject of
        ActingPermanent.Self -> Transformed.object transformed == bearer
        ActingPermanent.Matching f ->
          let oid = Transformed.object transformed
           in case Projection.viewWithLastKnown oid gs oid of
                Nothing -> False
                Just live ->
                  let sampled =
                        Count.overlaySnapshot
                          (Count.deployIn gs Zone.Battlefield)
                          (Transformed.lapsedGrants transformed)
                          (Transformed.characteristics transformed)
                          live {Filter.controller = Transformed.controller transformed}
                   in Filter.matches
                        bearerContext
                        sampled {Filter.attachedViews = Maybe.mapMaybe (Projection.viewWithLastKnownAnywhere gs) (Set.toAscList (Transformed.attachments transformed))}
                        f
    _ -> False
  -- CR 603.2: a permanent performed the watched action. The EVENT and nothing
  -- else -- each action's own rule places the moment it is recorded
  -- (Parun.Types.PermanentAction), and CR 701.44b and CR 701.50f fire even where
  -- some or all of the action was impossible.
  --
  -- The Self subject is a bare id comparison with no view, so a bearer that has
  -- since left is still answered about the event. A Filter subject describes
  -- the ACTOR, so the bearer only frames the match (the Filter.Context's source,
  -- its controller CR 109.5's "you"), and the actor is read through
  -- viewWithLastKnown: CR 701.44c and CR 701.50b ask for a gone actor as it last
  -- was, and the permanent turned face down is seen with CR 708.2's listed
  -- characteristics. An actor that is gone AND filed no last known information
  -- answers False.
  TriggerCondition.PermanentActs watched -> case event of
    GameEvent.PermanentActed acted ->
      PermanentActed.action acted == PermanentActed.action watched && case PermanentActed.permanent watched of
        ActingPermanent.Self -> PermanentActed.permanent acted == bearer
        ActingPermanent.Matching f ->
          let actor = PermanentActed.permanent acted
           in maybe False (\view -> Filter.matches bearerContext view f) (Projection.viewWithLastKnown actor gs actor)
    _ -> False
  -- CR 708.9: the cause alone. The permanent is gone by the scan (CR 400.7) and
  -- the condition names nothing else, so there is no view to read. A face-up
  -- merged permanent's face-down component is no face-down permanent, so its
  -- reveal (RevealCause.LeavingFaceDownComponent) does not match.
  TriggerCondition.FaceDownPermanentLeavesRevealed -> case event of
    GameEvent.Revealed r -> Revealed.cause r == RevealCause.LeavingFaceDown
    -- CR 708.9: the departure reveals the card to everyone; a look is not it.
    GameEvent.Looked {} -> False
    _ -> False
  -- CR 702.134c: the creature the BEARER IS ATTACHED TO mentored another. The
  -- event's first id is rule 702.134c's "first creature", the mentor, and this arm
  -- asks only whether that is the bearer's host -- the pairing with the second
  -- creature is the event's, decided where the mentor ability resolved.
  --
  -- CR 301.5a's "equipped creature" read off Object.attachedTo, which is where the
  -- Equipment records it, through Recipient.objectOf for CR 303.4's other
  -- destination: an Equipment attached to nothing, or an Aura enchanting a player,
  -- has no host id to compare and answers False.
  --
  -- A LIVE read, a Matching TurnedFaceUp's posture: nothing here is a zone
  -- change, so CR 603.10a's look-back does not reach this condition, and the
  -- attachment as it stands when the trigger is gathered is CR 603.2's own
  -- reading of "equipped creature".
  TriggerCondition.AttachedCreatureMentors -> case event of
    GameEvent.Mentored (Mentored.MkMentored mentor _) ->
      (Recipient.objectOf =<< Object.attachedTo =<< Game.lookupObject bearer gs) == Just mentor
    _ -> False
  -- CR 702.110b: a creature exploited a creature -- its controller sacrificed
  -- one as rule 702.110a's ability resolved.
  --
  -- A Self exploiter is PermanentActs' Self reading, line for line and for its
  -- reasons: a bare id comparison, no view. A Matching one (Skull Skaab) puts
  -- the event's id to a Filter instead.
  --
  -- Both Filters are read through viewWithLastKnown, PermanentSacrificed's
  -- posture and CR 603.10a's look-back: the exploit IS a sacrifice, so the
  -- exploited creature is gone by the time this is asked -- a token has ceased
  -- to exist outright -- and the exploiter may be that same creature. Nothing
  -- is a creature that is gone and filed no last known information, about which
  -- no Filter can answer.
  TriggerCondition.Exploits (ExploitTrigger.MkExploitTrigger exploiterSubject exploitedFilter) -> case event of
    GameEvent.Exploited (Exploited.MkExploited exploiter exploited) ->
      let admits oid f = maybe False (\view -> Filter.matches bearerContext view f) (Projection.viewWithLastKnown oid gs oid)
          exploiterAdmitted = case exploiterSubject of
            ActingPermanent.Self -> exploiter == bearer
            ActingPermanent.Matching f -> admits exploiter f
       in exploiterAdmitted && admits exploited exploitedFilter
    _ -> False
  -- CR 702.122e: the BEARER became crewed, which that rule defines as a crew
  -- ability of the bearer RESOLVING. PermanentActs' Self reading, line for line
  -- and for its reasons -- a bare id comparison, no view and no Filter, so a Vehicle
  -- that has since left the battlefield is still answered about the event.
  TriggerCondition.SelfBecomesCrewed frequency -> case event of
    GameEvent.BecameCrewed ev ->
      Crewing.vehicle ev == bearer && case frequency of
        TriggerFrequency.EveryTime -> True
        -- Mighty Servant of Leuk-o's "for the first time each turn", counted the way
        -- `attacks` counts declarations and for its reasons: the
        -- crewing being matched is already logged when the scan reaches here, so
        -- "the first time" is "the only one so far", and Engine.handoffTurn
        -- clearing the log is what makes it "each turn".
        TriggerFrequency.FirstTimeEachTurn -> crewingsOf bearer gs <= 1
    _ -> False
  -- CR 702.122b: the BEARER crewed a Vehicle, which that rule makes true of a
  -- creature as it is tapped to pay a Vehicle's crew cost -- GameEvent.Crewed,
  -- written at the payment, and not the arm above's resolution. A bare
  -- membership test for that arm's reasons -- no view and no Filter.
  --
  -- Read off the EVENT's set and not off the board: rule 702.122b is about what
  -- was tapped to pay, which nothing on the battlefield afterwards records --
  -- a creature tapped for any other reason is not among these.
  TriggerCondition.SelfCrewsVehicle -> case event of
    GameEvent.Crewed ev -> Set.member bearer (Crewing.crewedBy ev)
    _ -> False
  -- CR 702.112b: a permanent the Filter admits was given the renowned designation.
  -- A Matching TurnedFaceUp's arm above, line for line, and for its reasons: the
  -- permanent is read as it stands (viewWithLastKnown for CR 608.2h, a designation
  -- being no zone change), and the bearer contributes only CR 109.5's perspective
  -- and the Filter.Context's source -- which is what makes Filter.IsSource the
  -- self-scoped reading.
  TriggerCondition.PermanentBecomesDesignated (PermanentBecomesDesignated.MkPermanentBecomesDesignated wanted f) -> case event of
    -- The designations must MATCH, not merely both be present: Valeron Wardens'
    -- renown trigger must not fire when a creature you control becomes monstrous.
    GameEvent.BecameDesignated (BecameDesignated.MkBecameDesignated got oid)
      | got /= wanted -> False
      | otherwise -> case Projection.viewWithLastKnown oid gs oid of
          Nothing -> False
          Just view -> Filter.matches bearerContext view f
    _ -> False
  -- CR 709.5i: "such an ability triggers when that permanent has one of the two
  -- unlocked designations and gets the other, or when it has neither designation
  -- and gains both." The whole of that sentence is the flag the event carries,
  -- decided where the designation was written; this arm reads it and asks who
  -- unlocked the permanent.
  --
  -- NOT scoped to the bearer, which is where this parts company with
  -- SelfHalfUnlocked above: Balemurk Leech is a creature watching every Room on
  -- the board, so the bearer contributes only CR 109.5's perspective through
  -- `you`.
  --
  -- The relation is resolved against the player who UNLOCKED, which is rule
  -- 709.5i's own subject ("when a player 'fully unlocks' a permanent") read
  -- through CR 109.5's "you". The Room's CONTROLLER is the other reading and is
  -- rejected: the printed sentence puts "you" in the subject position and leaves
  -- "a Room" unqualified, so it is the act and not the permanent that "you"
  -- selects. The two readings agree on every printing, every printed unlock
  -- naming a Room its own controller controls; the actor is carried on the event
  -- because by the time this runs the board may have moved on.
  TriggerCondition.RoomFullyUnlocked relation -> case event of
    GameEvent.HalfUnlocked (HalfUnlocked.MkHalfUnlocked _ actor _ fully) ->
      fully && PlayerRelation.holds (Game.teams gs) relation you actor
    _ -> False
  -- CR 603.10a's sacrifice family: the log entry Event.sacrificeIn writes is the
  -- whole of the answer, which is exactly what makes the condition worth having.
  -- CR 700.4 makes every sacrifice a death, so the Moved event the same sacrifice
  -- records is indistinguishable from a destruction's or a mill's -- an arm that
  -- read the zone change instead would fire on both.
  --
  -- BOTH halves of the printed sentence are compared, against the two fields the
  -- event carries. CR 701.21a's sacrificing player is related to CR 109.5's `you`
  -- -- Vengeful Tracker's "an opponent" -- and the permanent is put to the Filter.
  -- Mayhem Devil's unrestricted wording spells itself out as AnyPlayer over the
  -- trivial Filter rather than as an absent payload.
  --
  -- viewWithLastKnown aimed at the sacrificed permanent twice over, Leaves'
  -- posture and CR 603.10a's own look-back: this event is recorded BEFORE the
  -- move, so by the time the trigger is gathered the permanent has left the
  -- battlefield, and a TOKEN has ceased to exist outright -- CR 111.7's
  -- parenthetical says the ability triggers anyway, which a live read could not
  -- honour. A Treasure sacrificed for mana is the case.
  --
  -- Nothing is a permanent that is gone AND filed no last known information, about
  -- which no Filter can honestly answer.
  TriggerCondition.PermanentSacrificed (PlayerActsOn.MkPlayerActsOn relation f) -> case event of
    GameEvent.PermanentSacrificed ev
      | PlayerRelation.holds (Game.teams gs) relation you (PermanentWasSacrificed.player ev) ->
          let victim = PermanentWasSacrificed.permanent ev
           in case Projection.viewWithLastKnown victim gs victim of
                Nothing -> False
                Just view -> Filter.matches bearerContext view f
    -- CR 700.4 again, from this side: a sacrifice DOES record a Moved event, and
    -- matching it here would answer twice for one sacrifice.
    GameEvent.Moved {} -> False
    _ -> False
  -- CR 603.1b: "a triggered ability may have more than one trigger condition".
  -- `any`, because the printed sentence joins them with "and whenever": each
  -- clause is its own occasion for the ability to trigger. Two clauses matching
  -- the SAME event fire the ability once here, which is also the right answer --
  -- CR 603.2 matches an event against "a triggered ability's trigger event", and
  -- the ability is one ability.
  TriggerCondition.AnyOf conditions -> any (\c -> matchesTriggerGiven bindings board gs bearer you c event) conditions
  -- CR 609.1: the narrowed condition, on an event a spell or ability's effect
  -- caused, that spell or ability's controller related to CR 109.5's "you" the
  -- way a Discarder discard relates the discarder. The controller is the one the
  -- event recorded as it happened (Moved.causedBy), so a later change of
  -- control cannot reach back.
  TriggerCondition.CausedBy narrowed ->
    maybe False (PlayerRelation.holds (Game.teams gs) (CausedBy.controller narrowed) you) (causeOf event)
      && matchesTriggerGiven bindings board gs bearer you (CausedBy.condition narrowed) event
  -- CR 603.3b's second class, the one condition in this type whose event is
  -- another ability triggering: "whenever the final chapter ability of a Saga you
  -- control triggers".
  --
  -- The event carries the triggered ability's SOURCE, its CONTROLLER as it
  -- triggered (CR 603.3a) and the ABILITY, and all three are read:
  --
  --   * the ability must be a chapter ability (CR 714.2b, through Saga.chapterOf,
  --     so this and the CountersChange arm above cannot drift about what a
  --     chapter symbol is);
  --   * its chapter must be the source's FINAL chapter number (CR 714.2d), which
  --     is why the source's projection is read rather than the event alone;
  --   * the source must be a Saga with one or more chapter abilities
  --     (Saga.tracksLore, CR 714.4 / 704.5s's own phrase). CR 714.2d gives a
  --     permanent with no chapter abilities a final chapter number of 0, so
  --     without that conjunct a "{r0}" chapter ability on any permanent at all
  --     would match -- no card prints one, and the gate is still the one the
  --     rule states.
  --
  -- NOT self-scoped: Historian's Boon is an enchantment watching somebody else's
  -- permanent, so the bearer contributes only CR 109.5's perspective through
  -- `you`, which the PlayerRelation reads the event's controller against.
  --
  -- The source is read through CR 608.2h's fallback
  -- (Projection.projectWithLastKnown), because CR 704.5s's exemption is not enough
  -- on its own: it keeps a Saga off the SACRIFICE while a chapter ability of its
  -- own is on the stack, but CR 704.5g still destroys a Saga that is also a
  -- creature and has lethal damage, in the very state-based action batch that runs
  -- before CR 117.5 places the trigger. A live read then projects an object with
  -- no subtypes and Saga.tracksLore declines it. CR 603.10's first sentence wants
  -- the objects as they were immediately after the event, and the record holds the
  -- projection taken as the Saga ceased -- the copy's chapters for a Saga that was
  -- a copy, not the printed card's. Proved by Parun.TriggerSpec's "CR 608.2h the
  -- watcher reads the dead Saga's last known information" and, for the copy, its
  -- "CR 707.2 a COPY of the Saga answers with the copy's chapters".
  TriggerCondition.SagaFinalChapterTriggers relation -> case event of
    -- A SOURCELESS inherent ability (CR 725.2, CR 702.179d) is never a chapter
    -- ability of a Saga, there being no Saga behind it to read lore counters off.
    GameEvent.AbilityTriggered record -> case AbilityTriggered.source record of
      TriggerSource.Sourceless -> False
      TriggerSource.OfObject srcId ->
        PlayerRelation.holds (Game.teams gs) relation you (AbilityTriggered.controller record)
          && ( let pc = Projection.projectWithLastKnown srcId gs
                in Saga.tracksLore pc && Saga.chapterOf (AbilityTriggered.ability record) == Just (Saga.finalChapterOf pc)
             )
    _ -> False
  -- CR 603.7: "when you lose control of the creature" -- Ray of Command's third
  -- sentence. The slot is read out of CR 603.7c's captured environment, so the
  -- creature this asks about is the one the spell targeted rather than whatever
  -- creature happens to change hands.
  --
  -- Binding.objectSlots and not Binding.objectsOf: the printed sentence is about
  -- ONE creature, and a slot holding a group or several targets names none of them
  -- here rather than any one of them.
  --
  -- `before == you` and nothing about `after`, because losing control is the whole
  -- of what the sentence asks. Event.sampleControl only mints the event when the
  -- two players differ, so no separate "and somebody else has it now" conjunct is
  -- needed for the match to mean a change.
  --
  -- The `== Just oid` conjunct is a REGRESSION FENCE rather than a proven
  -- behaviour: no board in the pool can tell it from `Map.member slot`. The only
  -- control changes a Ray of Command board sees are the reversions of the creatures
  -- its controller stole, all in one CR 514.2 sweep, and the ability taps its slot
  -- whichever of them matched -- CR 603.7b spending the one shot either way. A card
  -- whose controller can lose control of a DIFFERENT permanent while this entry is
  -- armed is what would observe it.
  TriggerCondition.LoseControlOfBound slot -> case event of
    GameEvent.ControlChanged (ControlChanged.MkControlChanged oid before _) ->
      Map.lookup slot (Binding.objectSlots bindings) == Just oid && before == you
    _ -> False
  -- CR 603.10d: the bearer itself changed hands away from `you`, the controller
  -- the scan offers it under for this event (Event.Trigger.lostControlOf).
  TriggerCondition.LoseControlOfSelf -> case event of
    GameEvent.ControlChanged (ControlChanged.MkControlChanged oid before _) -> oid == bearer && before == you
    _ -> False
  -- CR 309.4c: "when YOU move your venture marker into THIS room", so the
  -- mover must be the ability's controller, the dungeon card the marker is on
  -- must be the bearer, and the room must be this ability's own.
  -- Event.Trigger.inherentTriggers reaches it, with Dungeon.abilities' rooms.
  -- The mover test is a regression fence: CR 309.4 puts a player's marker only
  -- on a dungeon card they own, so the mover is always the controller.
  TriggerCondition.RoomEntered room -> case event of
    GameEvent.VentureMarkerEntered (VentureMarkerEntered.MkVentureMarkerEntered mover oid entered) -> mover == you && oid == bearer && entered == room
    _ -> False
  -- CR 603.2: this player performed the watched action, the relation reading
  -- the actor against CR 109.5's "you", the ability's controller (CR 603.3a).
  -- The EVENT and nothing else: each keyword action's own rule places the
  -- moment it is recorded (Parun.Types.PlayerAction), and several of them --
  -- CR 701.22d, 701.25d, 701.54d, 701.68d -- say it fires even where some or
  -- all of the action was impossible.
  TriggerCondition.PlayerActs watched -> case event of
    GameEvent.PlayerActed acted ->
      PlayerActed.action acted == PlayerActed.action watched
        && PlayerRelation.holds (Game.teams gs) (PlayerActed.player watched) you (PlayerActed.player acted)
    _ -> False
  -- CR 603.9: a player lost the game. The relation reads the loser against CR
  -- 109.5's "you", the ability's controller -- PlayerActs' shape. Game.teams
  -- is read off the settings (CR 800.2), so a loser who has already left is
  -- still judged against the team they played on.
  TriggerCondition.PlayerLosesGame relation -> case event of
    GameEvent.LostTheGame loser -> PlayerRelation.holds (Game.teams gs) relation you loser
    _ -> False
  -- CR 305.1: "whenever you play a land from exile" (Urianger Augurelt). The
  -- player is the one who played it, which CR 305.1 makes the special
  -- action's taker; the zone is the one it was played from.
  TriggerCondition.PlayerPlaysLand p -> case event of
    GameEvent.LandPlayed played ->
      PlayerRelation.holds (Game.teams gs) (PlaysLand.player p) you (LandPlayed.player played)
        && LandPlayed.from played == PlaysLand.from p
        -- The land as it arrived (CR 400.7i), read the way a Matching Enters
        -- reads an entrant, so Fires of Mount Doom's Filter.IsBound names the
        -- permanent Cast.playLand's follow moved the binding onto.
        && maybe False (\view -> Filter.matches bearerContext view (PlaysLand.filter p)) (postEventView board gs (LandPlayed.land played))
    _ -> False
  -- CR 701.62b: Paranormal Analyst's "whenever you manifest dread", which an
  -- empty library still fires -- why it watches the keyword action's own event
  -- rather than the moves inside it.
  TriggerCondition.PlayerManifestsDread relation -> case event of
    GameEvent.ManifestedDread ev -> PlayerRelation.holds (Game.teams gs) relation you (ManifestedDread.player ev)
    _ -> False
  -- CR 706.2: one die's RESULT, after every modifier, was the stated number,
  -- the roller read against CR 109.5's "you" as PlayerActs does.
  -- Per die rather than per instruction, since each die is its own roll.
  TriggerCondition.PlayerRollsResult watched -> case event of
    GameEvent.DieResultSettled settled ->
      DieResult.result settled == DieResult.result watched
        && PlayerRelation.holds (Game.teams gs) (DieResult.roller watched) you (DieResult.roller settled)
    _ -> False
  -- CR 702.159a / 701.52a: its controller rolled to visit, and the result is
  -- lit up on this Attraction. The lights are its printing's (Game.lightsOf);
  -- being an Attraction is read off CR 603.10's board, a conjunct no board
  -- observes, since nothing in data/cards/ takes the subtype away.
  TriggerCondition.Visit -> case event of
    GameEvent.RolledToVisit rolled ->
      DieResult.roller rolled == you
        && Set.member (DieResult.result rolled) (Game.lightsOf bearer gs)
        && maybe False (Set.member Subtype.Attraction . PC.subtypes . BattlefieldCandidate.characteristics) (Map.lookup bearer board)
    _ -> False
  -- CR 311.7: chaos ensued, whether the planar die's chaos symbol (CR 901.9b)
  -- or a resolving spell or ability said so.
  --
  -- Not implemented: chaos ensuing for one particular object (#5100).
  TriggerCondition.ChaosEnsues -> case event of
    GameEvent.ChaosEnsued -> True
    _ -> False
  -- CR 901.8 / 901.9c: the roller, read against CR 109.5's "you" as
  -- PlayerActs does, rolled the Planeswalker symbol.
  TriggerCondition.PlayerRollsPlaneswalker relation -> case event of
    GameEvent.PlanarDieRolled rolled -> PlanarDieRolled.face rolled == PlanarDieFace.Planeswalker && PlayerRelation.holds (Game.teams gs) relation you (PlanarDieRolled.roller rolled)
    _ -> False
  -- CR 701.32b / 904.9: "When you set this scheme in motion", against the
  -- event naming this very scheme -- and CR 312.5's encounter and CR 701.31d's
  -- "When you planeswalk to", the same move off a planar deck.
  TriggerCondition.SelfTurnedUpOffDeck -> case event of
    GameEvent.TurnedUpOffDeck e -> TurnedUpOffDeck.card e == bearer
    _ -> False
  -- CR 701.31d: "When you planeswalk away from [this plane]", against the
  -- planeswalk naming this very plane among those walked away from. The bearer
  -- is the id it had face up, which eventTriggers' `walkedAwayFrom` offers.
  TriggerCondition.SelfPlaneswalkedAwayFrom -> case event of
    GameEvent.TurnedUpOffDeck e -> Set.member bearer (TurnedUpOffDeck.awayFrom e)
    _ -> False
  -- CR 705.2: this player WON a coin flip, the relation reading the flipper
  -- against CR 109.5's "you" as PlayerActs does. Tavern Scoundrel is
  -- the You form.
  --
  -- The OUTCOME is a bar here, where PlayerAction.RollDice deliberately has none: CR
  -- 705.2 names the win itself, so a lost flip is a recorded event this must not
  -- match. CR 705.2's last sentence is why one seat answers -- "no other players
  -- are involved" -- so the losing side of a won flip is nobody.
  TriggerCondition.PlayerWinsCoinFlip relation -> case event of
    -- A flip with NO outcome (CR 705.2's first sentence) is not a won one, so
    -- Nothing answers False exactly as Just False does.
    GameEvent.CoinFlipped flipped -> CoinFlipped.won flipped == Just True && PlayerRelation.holds (Game.teams gs) relation you (CoinFlipped.flipper flipped)
    _ -> False
  -- CR 705.2: this player LOST a coin flip -- they called, and the face did not
  -- match. Karplusan Minotaur is the You form.
  --
  -- PlayerWinsCoinFlip's mirror, and the arm that makes CoinFlipped.won's Maybe
  -- observable: a winnerless flip answers False to both conditions, where a
  -- called-and-missed flip answers only this one.
  TriggerCondition.PlayerLosesCoinFlip relation -> case event of
    -- A flip with NO outcome (CR 705.2's first sentence) is not a lost one
    -- either: Nothing is the flip nobody called, where Just False is the call that
    -- missed.
    GameEvent.CoinFlipped flipped -> CoinFlipped.won flipped == Just False && PlayerRelation.holds (Game.teams gs) relation you (CoinFlipped.flipper flipped)
    _ -> False
  -- CR 702.170a / 702.170c: the bearer's own card became plotted. Self-scoped, so the
  -- match is the id and nothing else -- and the id the event carries is the
  -- CR 400.7 incarnation in exile, which is the bearer here because
  -- Event.eventTriggers finds this ability through its exile scan rather than
  -- on the battlefield (zonesTriggeredFrom below).
  TriggerCondition.SelfBecomesPlotted -> case event of
    GameEvent.Plotted plotted -> plotted == bearer
    _ -> False
  -- CR 701.3a read from the HOST: something became attached to the BEARER, and
  -- the Filter narrows WHAT. Two questions, and the split is the condition's
  -- shape -- a bare id comparison for the host (a Self Enters) and a Filter
  -- read for the attachment (a Matching TurnedFaceUp's arm), which is why the
  -- constructor carries one payload and matches on two objects.
  --
  -- Recipient.objectOf and not equality on the whole Recipient: CR 701.3a's
  -- destination is tagged by the attaching permanent's own rules text
  -- (Parun.Engine.Attach.attachmentFor), so an Aura arrives as a ToCreature and
  -- an Equipment as a ToCreature while nothing promises the bearer would be
  -- named the same way twice. A ToPlayer host has no object and declines here,
  -- which is right: the bearer of this condition is a permanent.
  --
  -- viewWithLastKnown for a Matching TurnedFaceUp's reason -- an attachment that
  -- is gone by the CR 117.5 boundary is still read as it was (CR 608.2h)
  -- instead of vanishing from the match.
  TriggerCondition.SelfBecomesAttachedBy f -> case event of
    GameEvent.BecameAttached a ->
      Recipient.objectOf (BecameAttached.host a) == Just bearer
        && ( case Projection.viewWithLastKnown (BecameAttached.attachment a) gs (BecameAttached.attachment a) of
               Nothing -> False
               Just view -> Filter.matches bearerContext view f
           )
    _ -> False
  -- CR 701.3a read from the ATTACHMENT: the BEARER became attached, and the
  -- Filter narrows what it went ONTO. The arm above's mirror, and the two
  -- questions swap sides -- a bare id comparison for the attachment, a Filter
  -- read for the host.
  --
  -- Recipient.objectOf and not equality on the whole Recipient, the arm above's
  -- reason. A ToPlayer host declines here: CR 702.5a's enchanted player is no
  -- object for the Filter to read, and Enormous Energy Blade's "a creature" would
  -- not admit one anyway. That decline is what makes the host binding guaranteed
  -- given a match, which eventBindingSlots needs.
  --
  -- viewWithLastKnown with the host as its OWN source, so CR 608.2h answers for a
  -- host that is already gone by the CR 117.5 boundary.
  TriggerCondition.SelfBecomesAttachedTo f -> case event of
    GameEvent.BecameAttached a ->
      BecameAttached.attachment a == bearer
        && ( case Recipient.objectOf (BecameAttached.host a) of
               Nothing -> False
               Just host -> case Projection.viewWithLastKnown host gs host of
                 Nothing -> False
                 Just view -> Filter.matches bearerContext view f
           )
    _ -> False
  -- CR 701.3d read from the attachment: the BEARER became unattached, and the
  -- Filter narrows what it came OFF. Structurally the arm above with the other
  -- event, which is what the two rules are.
  --
  -- viewWithLastKnown is load-bearing here rather than defensive: CR 701.3d
  -- counts the HOST leaving its zone as becoming unattached, so the ordinary case
  -- is a host that no longer exists, and CR 603.10c is the rule that says this
  -- ability looks back at it.
  TriggerCondition.SelfBecomesUnattachedFrom f -> case event of
    GameEvent.BecameUnattached a ->
      BecameUnattached.attachment a == bearer
        && ( case Recipient.objectOf (BecameUnattached.host a) of
               Nothing -> False
               Just host -> case Projection.viewWithLastKnown host gs host of
                 Nothing -> False
                 Just view -> Filter.matches bearerContext view f
           )
    _ -> False
  -- CR 123.3: a player the relation names put a sticker of one of these kinds
  -- on an object the filter admits, read as it is or as it last was.
  TriggerCondition.PlacesSticker (PlacesSticker.MkPlacesSticker relation kinds onto) -> case event of
    GameEvent.StickerPut put ->
      PlayerRelation.holds (Game.teams gs) relation you (StickerPut.placer put)
        && Set.member (StickerPut.kind put) kinds
        && case Projection.viewWithLastKnown (StickerPut.object put) gs (StickerPut.object put) of
          Nothing -> False
          Just view -> Filter.matches bearerContext view onto
    _ -> False
  where
    -- CR 603.7c: a delayed ability's filters read the objects its creating
    -- effect named, The Ruinous Powers' "a spell [cast] this way". `bindings`
    -- is empty for every other trigger, so their slot atoms stay vacuous.
    --
    -- The bearer's mana value too (CR 202.3, Projection.sourceContext), for a
    -- condition comparing against "this card"
    -- (Filter.Measures' OfSource operand): live for a bearer in a graveyard,
    -- and its last known information for one the event itself removed, CR
    -- 603.10a's look back. Parun.ZoneTriggerSpec's "CR 113.6m a Kami of
    -- Mourning grant returns the card when a greater creature dies" proves it.
    bearerContext = Projection.framedByBindings gs bindings (Projection.sourceContext gs (Just you) bearer)
    -- CR 102.1: the seats a TurnScope.PlayersTurn names, read from the bearer.
    scopeNamed = Count.scopePlayers (Projection.viewWithLastKnownAnywhere gs) bearerContext gs
    admitsTurn scope = Turn.turnScopeAdmits scopeNamed gs scope (GameState.activePlayer gs) you
    -- A damage condition's watched permanent, the damage's source or recipient:
    -- the bearer by id, or a permanent the Filter admits. The Filter reads it
    -- through `board`, CR 603.10's battlefield immediately after the damage:
    -- data/scenarios/event-trigger's "The Raven's Warning sees Venser's Sliver
    -- fly as it hit" proves it, and damage that kills Spirit Link's
    -- host also buries the Aura (CR 704.5m) before the log is scanned, and the
    -- link has to be read as it stood. A spell source is on no such board and is
    -- read from its last known information (CR 608.2h), Chandra's Phoenix's "red
    -- instant or sorcery spell".
    -- CR 113.7a / 608.2h: a source gone before its ability dealt the damage is
    -- judged in the zone it last existed in, so "a creature you control" still
    -- admits it. Scenario hooded-blightfang-destroys-for-noncombat-damage-from-a-pinger-gone-in-response.
    damageBy watched oid = case watched of
      ActingPermanent.Self -> oid == bearer
      ActingPermanent.Matching f -> maybe False (\view -> Filter.matches bearerContext (ProjectionView.lastZoned gs oid view) f) (postEventView board gs oid)
    -- CR 120.1: is the damage's recipient one this DamageRecipient admits?
    damagedIs target recipient = case recipient of
      DamageRecipient.Player relation -> maybe False (PlayerRelation.holds (Game.teams gs) relation you) (Recipient.playerOf target)
      DamageRecipient.Permanent cardType -> Set.member cardType (Projection.damagedCardTypes gs target)

-- CR 106.12a's second half: did an activation that produced @produced@ produce
-- the mana this condition specified? The narrowing half of the
-- PermanentTappedForMana arm above, where PlayerRelation.holds and
-- Filter.matches are the other two.
--
-- CR 607.2d's link is resolved by reading Object.chosenColors off the BEARER,
-- which is the object the triggered ability is on: Gauntlet of Power's "of the
-- chosen color" means the colour its own "As this artifact enters, choose a
-- color" settled. Parun.Engine.Mana.produced resolves ManaProduction.Chosen
-- the same way and off the same field, and a permanent with nothing chosen
-- narrows to nothing here for that function's reason -- a colour the engine
-- invented would be a player's choice made for them.
--
-- EXHAUSTIVE with no wildcard: a specification the rule adds owes an answer
-- here, and -Werror is what makes it.
producedSpecified :: GameState -> ObjectId -> ManaSpecification.ManaSpecification -> Set.Set ManaType.ManaType -> Bool
producedSpecified gs bearer specified produced = case specified of
  -- CR 106.12a's first half, "is tapped for mana": Parun.Engine.Cost.applyManaTriggers
  -- records the event only where the activation produced mana, so there is
  -- nothing left to ask.
  ManaSpecification.AnyMana -> True
  ManaSpecification.ChosenColor ->
    any (\color -> Set.member (ManaType.Colored color) produced) (Maybe.fromMaybe Set.empty (Game.currentChoice Chosen.Colors bearer gs))
  -- A regression fence: no card in data/cards/ writes a printed colour in a
  -- trigger, only in Crimson Hellkite's activation restriction.
  ManaSpecification.OfColor color -> Set.member (ManaType.Colored color) produced

-- CR 609.1: the controller of the spell or ability whose effect made this
-- event, on the two events that record one. Every other event records no
-- cause, so a CausedBy condition never matches it: a card whose condition
-- reads a cause off another event would add its field here.
causeOf :: GameEvent -> Maybe PlayerId
causeOf event = case event of
  GameEvent.Moved moved -> Moved.causedBy moved
  GameEvent.Discarded discarded -> Discarded.causedBy discarded
  _ -> Nothing
