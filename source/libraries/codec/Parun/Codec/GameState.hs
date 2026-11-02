{-# LANGUAGE ApplicativeDo #-}

-- | A game in progress, on the wire (#126).
module Parun.Codec.GameState where

import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Codec.AbilityTriggered as AbilityTriggered
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.ActiveAttackProhibition as ActiveAttackProhibition
import qualified Parun.Codec.ActiveAttackRequirement as ActiveAttackRequirement
import qualified Parun.Codec.ActiveBlockRequirement as ActiveBlockRequirement
import qualified Parun.Codec.ActiveCopy as ActiveCopy
import qualified Parun.Codec.ActiveEvasion as ActiveEvasion
import qualified Parun.Codec.ActiveObjectProhibition as ActiveObjectProhibition
import qualified Parun.Codec.ActivePlayerEffect as ActivePlayerEffect
import qualified Parun.Codec.ActiveReplacement as ActiveReplacement
import qualified Parun.Codec.Arrival as Arrival
import qualified Parun.Codec.AttackerDeclared as AttackerDeclared
import qualified Parun.Codec.BattlefieldCandidate as BattlefieldCandidate
import qualified Parun.Codec.Binding as Binding
import qualified Parun.Codec.Card as Card
import qualified Parun.Codec.CardName as CardName
import qualified Parun.Codec.CastFromZone as CastFromZone
import qualified Parun.Codec.Combat as Combat
import qualified Parun.Codec.ContinuousEffect as ContinuousEffect
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.DamageEvent as DamageEvent
import qualified Parun.Codec.Daytime as Daytime
import qualified Parun.Codec.DelayedTrigger as DelayedTrigger
import qualified Parun.Codec.EndTurnSignal as EndTurnSignal
import qualified Parun.Codec.EnteringTogether as EnteringTogether
import qualified Parun.Codec.EntryOrigin as EntryOrigin
import qualified Parun.Codec.EventGroup as EventGroup
import qualified Parun.Codec.ExileLink as ExileLink
import qualified Parun.Codec.ExtraTurn as ExtraTurn
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.GameSettings as GameSettings
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.IgnoredAbility as IgnoredAbility
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.LastKnown as LastKnown
import qualified Parun.Codec.LoggedEvent as LoggedEvent
import qualified Parun.Codec.Mana as Mana
import qualified Parun.Codec.ManaType as ManaType
import qualified Parun.Codec.ModifiedRoll as ModifiedRoll
import qualified Parun.Codec.Object as Object
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.OutsideObject as OutsideObject
import qualified Parun.Codec.PastActivation as PastActivation
import qualified Parun.Codec.PendingEntryEffect as PendingEntryEffect
import qualified Parun.Codec.PendingReplacementEffect as PendingReplacementEffect
import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.PhasedOut as PhasedOut
import qualified Parun.Codec.Player as Player
import qualified Parun.Codec.PlayerControl as PlayerControl
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Prevention as Prevention
import qualified Parun.Codec.Printing as Printing
import qualified Parun.Codec.PrintingId as PrintingId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Codec.RestartSignal as RestartSignal
import qualified Parun.Codec.Result as Result
import qualified Parun.Codec.ReturnWatch as ReturnWatch
import qualified Parun.Codec.SideDeck as SideDeck
import qualified Parun.Codec.SpellWasCast as SpellWasCast
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Card as Card.Type
import qualified Parun.Types.CardName as CardName.Type
import qualified Parun.Types.EndTurnSignal as EndTurnSignal.Type
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Printing as Printing.Type
import qualified Parun.Types.PrintingId as PrintingId.Type
import qualified Parun.Types.RestartSignal as RestartSignal.Type
import qualified Parun.Types.SlotName as SlotName.Type

-- | Every field but one, in the record's own order.
--
-- 'Fields.required' is kept for the fields no game can be missing -- `settings`,
-- `objects`, `players`, `turnOrder`, `activePlayer`, `phase` -- and for the
-- counters and clocks whose zero is a position rather than an absence:
-- `nextEventGroup`, `nextObjectId`, `nextPrintingId`, `nextTimestamp`,
-- `lastChoice`, `turnNumber`, and `remaining`, which is the rest of the turn
-- and not a collection that happens to be empty. `combat` stays required too,
-- and costs almost nothing now that Parun.Codec.Combat defaults its own fields:
-- a cleared combat (CR 511.3) writes @{"struckFirst":null}@.
--
-- Everything else is 'Fields.defaulted', which omits a field equal to its
-- default and reads an absence back as that same value, so the round trip is
-- unchanged and a state that has done nothing writes almost nothing. The trap
-- it introduces is that a mistyped key now decodes as the default instead of
-- failing as a missing one; rejecting unknown keys is not the fix, since
-- 'Parun.JsonCodec.Arm.armObject' already declines @additionalProperties@ for
-- forward compatibility.
--
-- The resolver goes to `printings` and nowhere else: Parun.Codec.Printing's
-- 'Printing.reference' writes a card's NAME where the resolver reproduces it and
-- the whole record where none can. It is the caller's, because @parun:registry@
-- sits above @parun:codec@ and a decoder cannot reach one.
--
-- GameState.printingIds is NOT written. It is `printings` read backwards, which
-- Parun.Types.GameState says at the field itself, so writing it would put the
-- same table on the wire twice and let the two disagree -- a document whose two
-- halves contradict each other has no meaning this decoder could pick. It is
-- rebuilt by `invert` below instead.
--
-- Its key is also a whole Printing, so it could not be an object key at all: it
-- would need an array of key/value pairs, duplicating every printing's entire
-- record a second time. That is the size argument, and it is the lesser one.
codec :: (CardName.Type.CardName -> Maybe Card.Type.Card) -> Codec.Codec GameState.GameState
codec resolve = Fields.object $ do
  settings <- Fields.required "settings" GameSettings.codec GameState.settings
  objects <- Fields.required "objects" (Common.naturalMap ObjectId.codec Object.codec) GameState.objects
  library <- Fields.defaulted "library" Map.empty (Common.naturalMap PlayerId.codec (Common.seq ObjectId.codec)) GameState.library
  hand <- Fields.defaulted "hand" Map.empty (Common.naturalMap PlayerId.codec (Common.seq ObjectId.codec)) GameState.hand
  graveyard <- Fields.defaulted "graveyard" Map.empty (Common.naturalMap PlayerId.codec (Common.seq ObjectId.codec)) GameState.graveyard
  battlefield <- Fields.defaulted "battlefield" Set.empty (Common.set ObjectId.codec) GameState.battlefield
  phasedOut <- Fields.defaulted "phasedOut" Map.empty (Common.naturalMap ObjectId.codec PhasedOut.codec) GameState.phasedOut
  exile <- Fields.defaulted "exile" Set.empty (Common.set ObjectId.codec) GameState.exile
  command <- Fields.defaulted "command" Set.empty (Common.set ObjectId.codec) GameState.command
  ante <- Fields.defaulted "ante" Set.empty (Common.set ObjectId.codec) GameState.ante
  sideDecks <- Fields.defaulted "sideDecks" Map.empty (Common.keyedList (Common.keyValue SideDeck.codec (Common.naturalMap PlayerId.codec (Common.seq ObjectId.codec)))) GameState.sideDecks
  stack <- Fields.defaulted "stack" [] (Common.list ObjectId.codec) GameState.stack
  stackedIn <- Fields.defaulted "stackedIn" Map.empty (Common.naturalMap ObjectId.codec EventGroup.codec) GameState.stackedIn
  players <- Fields.required "players" (Common.naturalMap PlayerId.codec Player.codec) GameState.players
  outsideObjects <- Fields.defaulted "outsideObjects" Map.empty (Common.naturalMap ObjectId.codec OutsideObject.codec) GameState.outsideObjects
  broughtIn <- Fields.defaulted "broughtIn" Seq.empty (Common.seq ObjectId.codec) GameState.broughtIn
  manaPool <- Fields.defaulted "manaPool" Map.empty (Common.naturalMap PlayerId.codec Mana.codec) GameState.manaPool
  combat <- Fields.required "combat" Combat.codec GameState.combat
  events <- Fields.defaulted "events" Seq.empty (Common.seq LoggedEvent.codec) GameState.events
  nextEventGroup <- Fields.required "nextEventGroup" EventGroup.codec GameState.nextEventGroup
  eventGroupDepth <- Fields.defaulted "eventGroupDepth" 0 Common.natural GameState.eventGroupDepth
  enteringTogether <- Fields.defaulted "enteringTogether" Nothing (Common.maybe EnteringTogether.codec) GameState.enteringTogether
  arrivals <- Fields.defaulted "arrivals" Nothing (Common.maybe (Common.seq Arrival.codec)) GameState.arrivals
  payingOnResolution <- Fields.defaulted "payingOnResolution" False Common.boolean GameState.payingOnResolution
  causing <- Fields.defaulted "causing" Nothing (Common.maybe PlayerId.codec) GameState.causing
  lastKnown <- Fields.defaulted "lastKnown" Map.empty (Common.naturalMap ObjectId.codec LastKnown.codec) GameState.lastKnown
  stackArchive <- Fields.defaulted "stackArchive" Map.empty (Common.naturalMap ObjectId.codec Object.codec) GameState.stackArchive
  scannedThrough <- Fields.defaulted "scannedThrough" 0 Common.natural GameState.scannedThrough
  battlefieldWhenTriggered <- Fields.defaulted "battlefieldWhenTriggered" Map.empty (Common.naturalMap EventGroup.codec (Common.naturalMap ObjectId.codec (BattlefieldCandidate.codec ProjectedCharacteristics.codec))) GameState.battlefieldWhenTriggered
  boardAfterEvent <- Fields.defaulted "boardAfterEvent" Map.empty (Common.naturalMap EventGroup.codec (codec resolve)) GameState.boardAfterEvent
  boardBeforeDeparture <- Fields.defaulted "boardBeforeDeparture" Map.empty (Common.naturalMap EventGroup.codec (codec resolve)) GameState.boardBeforeDeparture
  controlSample <- Fields.defaulted "controlSample" Map.empty (Common.naturalMap ObjectId.codec PlayerId.codec) GameState.controlSample
  damageScannedThrough <- Fields.defaulted "damageScannedThrough" 0 Common.natural GameState.damageScannedThrough
  delayedTriggers <- Fields.defaulted "delayedTriggers" Seq.empty (Common.seq DelayedTrigger.codec) GameState.delayedTriggers
  continuousEffects <- Fields.defaulted "continuousEffects" [] (Common.list (ContinuousEffect.codec Card.codec)) GameState.continuousEffects
  copyEffects <- Fields.defaulted "copyEffects" [] (Common.list ActiveCopy.codec) GameState.copyEffects
  replacements <- Fields.defaulted "replacements" [] (Common.list ActiveReplacement.codec) GameState.replacements
  pendingPreventionRiders <- Fields.defaulted "pendingPreventionRiders" Seq.empty (Common.seq Prevention.codec) GameState.pendingPreventionRiders
  pendingReplacementEffects <- Fields.defaulted "pendingReplacementEffects" Seq.empty (Common.seq PendingReplacementEffect.codec) GameState.pendingReplacementEffects
  contested <- Fields.defaulted "contested" Map.empty (Common.naturalMap ObjectId.codec (Common.maybe ObjectId.codec)) GameState.contested
  ambientAmounts <- Fields.defaulted "ambientAmounts" Map.empty (Common.textMap SlotName.Type.unwrap (Right . SlotName.Type.MkSlotName) Common.natural) GameState.ambientAmounts
  detachedBindings <- Fields.defaulted "detachedBindings" Map.empty (Common.naturalMap ObjectId.codec Binding.codecMap) GameState.detachedBindings
  pendingEntryEffects <- Fields.defaulted "pendingEntryEffects" Seq.empty (Common.seq PendingEntryEffect.codec) GameState.pendingEntryEffects
  enteringBeside <- Fields.defaulted "enteringBeside" Set.empty (Common.set ObjectId.codec) GameState.enteringBeside
  enteringSubjects <- Fields.defaulted "enteringSubjects" Map.empty (Common.naturalMap ObjectId.codec (Common.maybe EntryOrigin.codec)) GameState.enteringSubjects
  enteringPending <- Fields.defaulted "enteringPending" Map.empty (Common.naturalMap ObjectId.codec PlayerId.codec) GameState.enteringPending
  refusedEntries <- Fields.defaulted "refusedEntries" Nothing (Common.maybe (Common.set ObjectId.codec)) GameState.refusedEntries
  enteringCounters <- Fields.defaulted "enteringCounters" Map.empty (Common.naturalMap ObjectId.codec (Common.multiset (CounterKind.codec Keyword.codec))) GameState.enteringCounters
  copyExceptionCounters <- Fields.defaulted "copyExceptionCounters" Map.empty (Common.naturalMap ObjectId.codec (Common.multiset (CounterKind.codec Keyword.codec))) GameState.copyExceptionCounters
  playerEffects <- Fields.defaulted "playerEffects" [] (Common.list ActivePlayerEffect.codec) GameState.playerEffects
  blockRequirements <- Fields.defaulted "blockRequirements" [] (Common.list ActiveBlockRequirement.codec) GameState.blockRequirements
  attackRequirements <- Fields.defaulted "attackRequirements" [] (Common.list ActiveAttackRequirement.codec) GameState.attackRequirements
  objectProhibitions <- Fields.defaulted "objectProhibitions" [] (Common.list ActiveObjectProhibition.codec) GameState.objectProhibitions
  attackProhibitions <- Fields.defaulted "attackProhibitions" [] (Common.list ActiveAttackProhibition.codec) GameState.attackProhibitions
  evasions <- Fields.defaulted "evasions" [] (Common.list ActiveEvasion.codec) GameState.evasions
  ignoredAbilities <- Fields.defaulted "ignoredAbilities" [] (Common.list IgnoredAbility.codec) GameState.ignoredAbilities
  turnOrder <- Fields.required "turnOrder" (Common.list PlayerId.codec) GameState.turnOrder
  activePlayer <- Fields.required "activePlayer" PlayerId.codec GameState.activePlayer
  phase <- Fields.required "phase" Phase.codec GameState.phase
  remaining <- Fields.required "remaining" (Common.seq Phase.codec) GameState.remaining
  priority <- Fields.defaulted "priority" Nothing (Common.maybe PlayerId.codec) GameState.priority
  passed <- Fields.defaulted "passed" Set.empty (Common.set PlayerId.codec) GameState.passed
  turnNumber <- Fields.required "turnNumber" Common.natural GameState.turnNumber
  turnsBegun <- Fields.defaulted "turnsBegun" Map.empty (Common.naturalMap PlayerId.codec Common.natural) GameState.turnsBegun
  result <- Fields.defaulted "result" Nothing (Common.maybe Result.codec) GameState.result
  restartSignal <- Fields.defaulted "restartSignal" RestartSignal.Type.Playing RestartSignal.codec GameState.restartSignal
  endTurnSignal <- Fields.defaulted "endTurnSignal" EndTurnSignal.Type.Running EndTurnSignal.codec GameState.endTurnSignal
  nextObjectId <- Fields.required "nextObjectId" ObjectId.codec GameState.nextObjectId
  printings <- Fields.defaulted "printings" Map.empty (Common.naturalMap PrintingId.codec (Printing.reference resolve)) GameState.printings
  lookedUp <- Fields.defaulted "lookedUp" Set.empty (Common.set PrintingId.codec) GameState.lookedUp
  referenceNames <- Fields.defaulted "referenceNames" Map.empty (Common.keyedList (Common.keyValue (Filter.codec Keyword.codec) (Common.set CardName.codec))) GameState.referenceNames
  outsideCopies <- Fields.defaulted "outsideCopies" Set.empty (Common.set ObjectId.codec) GameState.outsideCopies
  namedCopyChoices <- Fields.defaulted "namedCopyChoices" Map.empty (Common.naturalMap ObjectId.codec (Common.set CardName.codec)) GameState.namedCopyChoices
  notedCards <- Fields.defaulted "notedCards" Map.empty (Common.naturalMap ObjectId.codec PrintingId.codec) GameState.notedCards
  notedMana <- Fields.defaulted "notedMana" Map.empty (Common.naturalMap ObjectId.codec (Common.seq ManaType.codec)) GameState.notedMana
  nextPrintingId <- Fields.required "nextPrintingId" PrintingId.codec GameState.nextPrintingId
  nextTimestamp <- Fields.required "nextTimestamp" Timestamp.codec GameState.nextTimestamp
  lastChoice <- Fields.required "lastChoice" Timestamp.codec GameState.lastChoice
  loopInvolvement <- Fields.defaulted "loopInvolvement" Map.empty (Common.naturalMap PlayerId.codec Timestamp.codec) GameState.loopInvolvement
  drewFromEmpty <- Fields.defaulted "drewFromEmpty" Set.empty (Common.set PlayerId.codec) GameState.drewFromEmpty
  fellShort <- Fields.defaulted "fellShort" 0 Common.natural GameState.fellShort
  landsPlayed <- Fields.defaulted "landsPlayed" Map.empty (Common.naturalMap PlayerId.codec Common.natural) GameState.landsPlayed
  cardsPlayed <- Fields.defaulted "cardsPlayed" Map.empty (Common.naturalMap ObjectId.codec PlayerId.codec) GameState.cardsPlayed
  drawsThisTurn <- Fields.defaulted "drawsThisTurn" Map.empty (Common.naturalMap PlayerId.codec Common.natural) GameState.drawsThisTurn
  keptFaceDown <- Fields.defaulted "keptFaceDown" Nothing (Common.maybe (Common.naturalMap ObjectId.codec Common.natural)) GameState.keptFaceDown
  announcedTops <- Fields.defaulted "announcedTops" Nothing (Common.maybe (Common.naturalMap PlayerId.codec ObjectId.codec)) GameState.announcedTops
  departedThisTurn <- Fields.defaulted "departedThisTurn" Set.empty (Common.set PlayerId.codec) GameState.departedThisTurn
  couldAttackThisTurn <- Fields.defaulted "couldAttackThisTurn" Set.empty (Common.set ObjectId.codec) GameState.couldAttackThisTurn
  -- Common.repeats, for Parun.Codec.Object's activatedOnce reason.
  activatedThisTurn <- Fields.defaulted "activatedThisTurn" Map.empty (Common.naturalMap ObjectId.codec (Common.repeats (ActivatedAbility.codec Card.codec (GrantedAbility.codec Card.codec)))) GameState.activatedThisTurn
  activationsThisTurn <- Fields.defaulted "activationsThisTurn" Seq.empty (Common.seq PastActivation.codec) GameState.activationsThisTurn
  castPermissionsUsedThisTurn <- Fields.defaulted "castPermissionsUsedThisTurn" Map.empty (Common.naturalMap ObjectId.codec (Common.set CastFromZone.codec)) GameState.castPermissionsUsedThisTurn
  rollModifiersUsedThisTurn <- Fields.defaulted "rollModifiersUsedThisTurn" Map.empty (Common.naturalMap ObjectId.codec (Common.set ModifiedRoll.codec)) GameState.rollModifiersUsedThisTurn
  triggeredThisGame <- Fields.defaulted "triggeredThisGame" Seq.empty (Common.seq AbilityTriggered.codec) GameState.triggeredThisGame
  pendingControl <- Fields.defaulted "pendingControl" Map.empty (Common.naturalMap PlayerId.codec PlayerControl.codec) GameState.pendingControl
  control <- Fields.defaulted "control" Map.empty (Common.naturalMap PlayerId.codec (Common.nonEmpty PlayerControl.codec)) GameState.control
  monarch <- Fields.defaulted "monarch" Nothing (Common.maybe PlayerId.codec) GameState.monarch
  initiative <- Fields.defaulted "initiative" Nothing (Common.maybe PlayerId.codec) GameState.initiative
  daytime <- Fields.defaulted "daytime" Nothing (Common.maybe Daytime.codec) GameState.daytime
  spellsCastLastTurn <- Fields.defaulted "spellsCastLastTurn" 0 Common.natural GameState.spellsCastLastTurn
  eventsLastTurn <- Fields.defaulted "eventsLastTurn" Seq.empty (Common.seq LoggedEvent.codec) GameState.eventsLastTurn
  castsBeforeThisTurn <- Fields.defaulted "castsBeforeThisTurn" Seq.empty (Common.seq SpellWasCast.codec) GameState.castsBeforeThisTurn
  damageBeforeThisTurn <- Fields.defaulted "damageBeforeThisTurn" Seq.empty (Common.seq DamageEvent.codec) GameState.damageBeforeThisTurn
  attacksInOwnLastTurn <- Fields.defaulted "attacksInOwnLastTurn" Map.empty (Common.naturalMap PlayerId.codec (Common.seq AttackerDeclared.codec)) GameState.attacksInOwnLastTurn
  resolvedNames <- Fields.defaulted "resolvedNames" Map.empty (Common.naturalMap PlayerId.codec (Common.set CardName.codec)) GameState.resolvedNames
  movedUntil <- Fields.defaulted "movedUntil" Map.empty (Common.naturalMap ObjectId.codec ReturnWatch.codec) GameState.movedUntil
  haunting <- Fields.defaulted "haunting" Map.empty (Common.naturalMap ObjectId.codec ObjectId.codec) GameState.haunting
  encoded <- Fields.defaulted "encoded" Map.empty (Common.naturalMap ObjectId.codec ObjectId.codec) GameState.encoded
  exiledWith <- Fields.defaulted "exiledWith" Map.empty (Common.naturalMap ObjectId.codec ExileLink.codec) GameState.exiledWith
  enteredWith <- Fields.defaulted "enteredWith" Map.empty (Common.naturalMap ObjectId.codec ObjectId.codec) GameState.enteredWith
  exilePiles <- Fields.defaulted "exilePiles" Map.empty (Common.naturalMap ObjectId.codec Timestamp.codec) GameState.exilePiles
  extraTurns <- Fields.defaulted "extraTurns" [] (Common.list ExtraTurn.codec) GameState.extraTurns
  subgamesThisMatch <- Fields.defaulted "subgamesThisMatch" 0 Common.natural GameState.subgamesThisMatch
  turnAnchor <- Fields.defaulted "turnAnchor" Nothing (Common.maybe PlayerId.codec) GameState.turnAnchor
  extraTurnUnderWay <- Fields.defaulted "extraTurnUnderWay" Nothing (Common.maybe Timestamp.codec) GameState.extraTurnUnderWay
  rollingDie <- Fields.defaulted "rollingDie" Nothing (Common.maybe Common.natural) GameState.rollingDie
  rerollRequested <- Fields.defaulted "rerollRequested" False Common.boolean GameState.rerollRequested
  pure
    GameState.MkGameState
      { GameState.settings = settings,
        GameState.objects = objects,
        GameState.library = library,
        GameState.hand = hand,
        GameState.graveyard = graveyard,
        GameState.battlefield = battlefield,
        GameState.phasedOut = phasedOut,
        GameState.exile = exile,
        GameState.command = command,
        GameState.ante = ante,
        GameState.sideDecks = sideDecks,
        GameState.stack = stack,
        GameState.stackedIn = stackedIn,
        GameState.players = players,
        GameState.outsideObjects = outsideObjects,
        GameState.broughtIn = broughtIn,
        GameState.manaPool = manaPool,
        GameState.combat = combat,
        GameState.events = events,
        GameState.nextEventGroup = nextEventGroup,
        GameState.eventGroupDepth = eventGroupDepth,
        GameState.enteringTogether = enteringTogether,
        GameState.arrivals = arrivals,
        GameState.payingOnResolution = payingOnResolution,
        GameState.causing = causing,
        GameState.lastKnown = lastKnown,
        GameState.stackArchive = stackArchive,
        GameState.scannedThrough = scannedThrough,
        GameState.battlefieldWhenTriggered = battlefieldWhenTriggered,
        GameState.boardAfterEvent = boardAfterEvent,
        GameState.boardBeforeDeparture = boardBeforeDeparture,
        GameState.controlSample = controlSample,
        GameState.damageScannedThrough = damageScannedThrough,
        GameState.delayedTriggers = delayedTriggers,
        GameState.continuousEffects = continuousEffects,
        GameState.copyEffects = copyEffects,
        GameState.replacements = replacements,
        GameState.pendingPreventionRiders = pendingPreventionRiders,
        GameState.pendingReplacementEffects = pendingReplacementEffects,
        GameState.contested = contested,
        GameState.ambientAmounts = ambientAmounts,
        GameState.detachedBindings = detachedBindings,
        GameState.pendingEntryEffects = pendingEntryEffects,
        GameState.enteringBeside = enteringBeside,
        GameState.enteringSubjects = enteringSubjects,
        GameState.enteringPending = enteringPending,
        GameState.refusedEntries = refusedEntries,
        GameState.enteringCounters = enteringCounters,
        GameState.copyExceptionCounters = copyExceptionCounters,
        GameState.playerEffects = playerEffects,
        GameState.blockRequirements = blockRequirements,
        GameState.attackRequirements = attackRequirements,
        GameState.objectProhibitions = objectProhibitions,
        GameState.attackProhibitions = attackProhibitions,
        GameState.evasions = evasions,
        GameState.ignoredAbilities = ignoredAbilities,
        GameState.turnOrder = turnOrder,
        GameState.activePlayer = activePlayer,
        GameState.phase = phase,
        GameState.remaining = remaining,
        GameState.priority = priority,
        GameState.passed = passed,
        GameState.turnNumber = turnNumber,
        GameState.turnsBegun = turnsBegun,
        GameState.result = result,
        GameState.restartSignal = restartSignal,
        GameState.endTurnSignal = endTurnSignal,
        GameState.nextObjectId = nextObjectId,
        GameState.printings = printings,
        GameState.lookedUp = lookedUp,
        GameState.referenceNames = referenceNames,
        GameState.outsideCopies = outsideCopies,
        GameState.namedCopyChoices = namedCopyChoices,
        GameState.notedCards = notedCards,
        GameState.notedMana = notedMana,
        GameState.nextPrintingId = nextPrintingId,
        GameState.nextTimestamp = nextTimestamp,
        GameState.lastChoice = lastChoice,
        GameState.loopInvolvement = loopInvolvement,
        GameState.drewFromEmpty = drewFromEmpty,
        GameState.fellShort = fellShort,
        GameState.landsPlayed = landsPlayed,
        GameState.cardsPlayed = cardsPlayed,
        GameState.drawsThisTurn = drawsThisTurn,
        GameState.keptFaceDown = keptFaceDown,
        GameState.announcedTops = announcedTops,
        GameState.departedThisTurn = departedThisTurn,
        GameState.couldAttackThisTurn = couldAttackThisTurn,
        GameState.activatedThisTurn = activatedThisTurn,
        GameState.activationsThisTurn = activationsThisTurn,
        GameState.castPermissionsUsedThisTurn = castPermissionsUsedThisTurn,
        GameState.rollModifiersUsedThisTurn = rollModifiersUsedThisTurn,
        GameState.triggeredThisGame = triggeredThisGame,
        GameState.pendingControl = pendingControl,
        GameState.control = control,
        GameState.monarch = monarch,
        GameState.initiative = initiative,
        GameState.daytime = daytime,
        GameState.spellsCastLastTurn = spellsCastLastTurn,
        GameState.eventsLastTurn = eventsLastTurn,
        GameState.castsBeforeThisTurn = castsBeforeThisTurn,
        GameState.damageBeforeThisTurn = damageBeforeThisTurn,
        GameState.attacksInOwnLastTurn = attacksInOwnLastTurn,
        GameState.resolvedNames = resolvedNames,
        GameState.movedUntil = movedUntil,
        GameState.haunting = haunting,
        GameState.encoded = encoded,
        GameState.exiledWith = exiledWith,
        GameState.enteredWith = enteredWith,
        GameState.exilePiles = exilePiles,
        GameState.extraTurns = extraTurns,
        GameState.subgamesThisMatch = subgamesThisMatch,
        GameState.turnAnchor = turnAnchor,
        GameState.extraTurnUnderWay = extraTurnUnderWay,
        GameState.rollingDie = rollingDie,
        GameState.rerollRequested = rerollRequested,
        -- Derived rather than written: see the note above.
        GameState.printingIds = invert printings
      }

-- | `printings` read backwards, which is what GameState.printingIds holds.
--
-- Exact, because Parun.Engine.Game.intern is idempotent: a printing already in
-- the table answers with the id it already has, so no two ids name one printing
-- and the inversion loses nothing. That idempotence is asserted by Parun.GameSpec's
-- "intern is idempotent for a printing already in the table", and the inversion
-- itself by Parun.CodecIntegrationSpec's "the intern table survives, though only
-- half of it is written".
invert :: Map.Map PrintingId.Type.PrintingId Printing.Type.Printing -> Map.Map Printing.Type.Printing PrintingId.Type.PrintingId
invert = Map.fromList . fmap (\(i, p) -> (p, i)) . Map.toList
