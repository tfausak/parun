-- | CR 732.3: a fragmented loop, where each player involved takes an
-- independent action and the game returns to a state it was in before. The
-- active player, or the first involved player in turn order from them, must
-- then make a different game choice -- at the priority grain CR 732.1 names,
-- a different action -- so the loop does not continue.
--
-- Not a choice made for anyone: the rule narrows the named player's menu, and
-- CR 732.5 keeps Pass on it.
--
-- UNDER-DETECTION is the safe direction throughout. A state this module fails
-- to recognise as a repeat leaves the menu as it was, so every approximation
-- here errs towards seeing no loop.
module Pawl.Engine.Fragmented where

import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Keyword as Keyword
import qualified Pawl.Engine.Planechase as Planechase
import qualified Pawl.Extra.Int as Int
import qualified Pawl.Types.Acquisition as Acquisition
import Pawl.Types.Action (Action)
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.ActiveCopy as ActiveCopy
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.Completion as Completion
import qualified Pawl.Types.ContinuousEffect as ContinuousEffect
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.EventGroup as EventGroup
import Pawl.Types.GameEvent (GameEvent)
import qualified Pawl.Types.GameEvent as GameEvent
import Pawl.Types.GameState (GameState)
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import Pawl.Types.LoopTrail (LoopTrail)
import qualified Pawl.Types.LoopTrail as LoopTrail
import qualified Pawl.Types.Mana as Mana
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.Modal as Modal
import qualified Pawl.Types.Mode as Mode
import qualified Pawl.Types.ModeSelection as ModeSelection
import qualified Pawl.Types.Modification as Modification
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Player as Player
import qualified Pawl.Types.PlayerActed as PlayerActed
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Printing as Printing
import qualified Pawl.Types.PrintingId as PrintingId
import Pawl.Types.StateDigest (StateDigest)
import qualified Pawl.Types.StateDigest as StateDigest
import qualified Pawl.Types.StickerPlacement as StickerPlacement
import qualified Pawl.Types.Timestamp as Timestamp

-- | The game state as CR 732.3 compares it: the whole record, by its derived
-- Eq, less the fields below. A RECORD UPDATE rather than a field list, so a
-- field added later is compared by default and can only ever prevent a
-- detection -- Pawl.Engine.Interchangeable.objects' posture, whole-Object Eq
-- less the timestamp.
--
-- Dropped as bookkeeping no card reads: the id, timestamp, printing and event
-- group supplies; CR 104.4b's `lastChoice` and `loopInvolvement`; the
-- grow-only printing interning; and the scan state keyed off the log
-- (`scannedThrough`, `damageScannedThrough`, `battlefieldWhenTriggered`,
-- `controlSample`, `stackedIn`). `lastKnown` and `stackArchive` are keyed by ids that have
-- left (CR 400.7), so an entry is reachable only through a kept field holding
-- that id.
--
-- Dropped as history a card CAN read: `events` and `activationsThisTurn`.
-- Compared, no state could recur, since every action appends to both; so they
-- ride along uncompared, and `lapIsRead` asks whether anything in the game
-- reads what the loop appended to them.
--
-- Object ids are compared as they stand, so a loop that moves a card (CR
-- 400.7) is never detected.
digest :: GameState -> StateDigest
digest gs =
  let (effects, objects) = canonicalStamps gs
   in StateDigest.MkStateDigest
        { StateDigest.unwrap =
            gs
              { GameState.events = Seq.empty,
                GameState.activationsThisTurn = Seq.empty,
                GameState.nextObjectId = ObjectId.MkObjectId 0,
                GameState.nextTimestamp = Timestamp.MkTimestamp 0,
                GameState.nextPrintingId = PrintingId.MkPrintingId 0,
                GameState.nextEventGroup = EventGroup.MkEventGroup 0,
                GameState.eventGroupDepth = 0,
                GameState.lastChoice = Timestamp.MkTimestamp 0,
                GameState.loopInvolvement = Map.empty,
                GameState.printings = Map.empty,
                GameState.printingIds = Map.empty,
                GameState.scannedThrough = 0,
                GameState.damageScannedThrough = 0,
                GameState.battlefieldWhenTriggered = Map.empty,
                GameState.controlSample = Map.empty,
                GameState.lastKnown = Map.empty,
                GameState.stackArchive = Map.empty,
                GameState.stackedIn = Map.empty,
                -- Canonical rather than dropped, so CR 732.3's own example recurs,
                -- and a loop that moves a counter back.
                GameState.continuousEffects = effects,
                GameState.objects = objects,
                -- Canonical rather than dropped: a payment leaves an empty pool
                -- behind where there was no entry, and no card tells the two apart.
                GameState.manaPool = Map.filter (not . null . Mana.unwrap) (GameState.manaPool gs)
              },
          StateDigest.events = GameState.events gs,
          StateDigest.activations = GameState.activationsThisTurn gs
        }

-- | CR 732.3 over the stamps an action leaves behind -- the stored continuous
-- effects (CR 611.2a) and the counters' (CR 613.7c) -- as the game can tell
-- them apart. A row is dropped where a later one from the same source, over
-- the same fixed set (CR 611.2c) and ending with it, `erases` it, which leaves
-- nothing it did standing (CR 613.7); a counter stamp, where the object has no
-- counters of its kind, which leaves it inert. The rest stamped after every
-- other stamp CR 613.7 orders them against (`layeredStamps`) are then
-- restamped in order from just above the latest of those, since only their
-- order is ever read (`digest` drops GameState.nextTimestamp).
--
-- Pawl.FragmentedSpec's Mist Dragon cases prove both halves for the rows, its
-- Arcanum Wings case the floor, and its Grim Poppet case both for the
-- counters.
canonicalStamps :: GameState -> ([ContinuousEffect.ContinuousEffect Card.Card], Map.Map ObjectId.ObjectId Object.Object)
canonicalStamps gs =
  let rows = GameState.continuousEffects gs
      live obj = obj {Object.counterTimestamps = Map.filterWithKey (\kind _ -> Map.findWithDefault 0 kind (Object.counters obj) > 0) (Object.counterTimestamps obj)}
      objects = fmap live (GameState.objects gs)
      erased row = any (supersedes row) rows
      supersedes row later =
        ContinuousEffect.timestamp later > ContinuousEffect.timestamp row
          && ContinuousEffect.source later == ContinuousEffect.source row
          && ContinuousEffect.affected later == ContinuousEffect.affected row
          && ContinuousEffect.expiry later == ContinuousEffect.expiry row
          && erases (ContinuousEffect.modification later) (ContinuousEffect.modification row)
      kept = filter (not . erased) rows
      floor_ = maximum (Timestamp.MkTimestamp 0 : layeredStamps gs)
      -- CR 607.5's no-duration copy stamps (Object.acquisition) move too; a
      -- stored copy row's stamp is under the floor, so a stored result keyed by
      -- one is left as it stands. A REGRESSION FENCE: no test loops a
      -- no-duration copy.
      copiedAt obj = case Object.acquisition obj of
        Acquisition.Copied ts -> [ts]
        Acquisition.Own -> []
      movable = fmap ContinuousEffect.timestamp kept <> foldMap (Map.elems . Object.counterTimestamps) objects <> foldMap copiedAt objects
      above = Set.fromList (filter (> floor_) movable)
      reacquire acquisition = case acquisition of
        Acquisition.Copied ts -> Acquisition.Copied (restamp ts)
        Acquisition.Own -> Acquisition.Own
      restamp ts = case Set.lookupIndex ts above of
        Just rank -> Timestamp.MkTimestamp (Timestamp.unwrap floor_ + 1 + Int.toNaturalSaturating rank)
        Nothing -> ts
   in ( fmap (\row -> row {ContinuousEffect.timestamp = restamp (ContinuousEffect.timestamp row)}) kept,
        fmap (\obj -> obj {Object.counterTimestamps = fmap restamp (Object.counterTimestamps obj), Object.acquisition = reacquire (Object.acquisition obj), Object.storedResults = Map.mapKeysWith (Map.unionWith (+)) reacquire (Object.storedResults obj)}) objects
      )

-- | Does `later`, applied after `earlier` to the same objects, leave nothing
-- `earlier` did? A removal of a keyword (CR 613.1f) erases an earlier removal
-- of it, and an earlier grant of it where the keyword has no family: a
-- protection grant is rebaked (Pawl.Engine.Keyword.grantedBy), so what it
-- grants need not be what is removed. A grant erases nothing, two grants of a
-- keyword counting twice (Pawl.Engine.Projection.applyModification).
--
-- The family guard is a regression fence: no test loops a protection grant.
erases :: Modification.Modification ability -> Modification.Modification ability -> Bool
erases later earlier = case (later, earlier) of
  (Modification.LoseKeyword lost, Modification.LoseKeyword keyword) -> lost == keyword
  (Modification.LoseKeyword lost, Modification.GainKeyword keyword) -> lost == keyword && Maybe.isNothing (Keyword.familyOf keyword)
  _ -> False

-- Every stamp CR 613.7 orders a stored continuous effect or a counter
-- against, bar those two kinds themselves: each object's own (CR 613.7a,
-- 613.7d), its stickers' (613.7k) and the moments it was turned over or became
-- a world, and each stored copy effect's.
layeredStamps :: GameState -> [Timestamp.Timestamp]
layeredStamps gs =
  concatMap
    ( \obj ->
        Object.timestamp obj
          : fmap StickerPlacement.timestamp (Foldable.toList (Object.stickers obj))
            <> Maybe.maybeToList (Object.turnedOverAt obj)
            <> Maybe.maybeToList (Object.worldSince obj)
    )
    (Map.elems (GameState.objects gs))
    <> fmap ActiveCopy.timestamp (GameState.copyEffects gs)

-- | CR 732.3's example makes "nothing in the game cares how many times an
-- ability has been activated" the precondition: does anything in the game
-- read the history appended between `there`, a state the loop passed through,
-- and `gs`, the same state again? Asked of what was appended rather than of
-- the whole history, so a reader of events the loop never writes -- Khabál
-- Ghoul's deaths -- leaves the loop detectable. History that is not an
-- extension of `there`'s counts as read.
lapIsRead :: StateDigest -> GameState -> Bool
lapIsRead there gs =
  case (appended (StateDigest.events there) (GameState.events gs), appended (StateDigest.activations there) (GameState.activationsThisTurn gs)) of
    (Just events, Just activations) ->
      let wrote reader = case reader of
            Nothing -> not (Seq.null events && Seq.null activations)
            Just readsEvent -> any (readsEvent . LoggedEvent.event) events
       in any wrote (readers gs)
    _ -> True
  where
    appended :: (Eq a) => Seq.Seq a -> Seq.Seq a -> Maybe (Seq.Seq a)
    appended before after =
      let (prefix, rest) = Seq.splitAt (Seq.length before) after
       in if prefix == before then Just rest else Nothing

-- | What one reader of the history reads: the logged events it folds over, or
-- Nothing for the whole of it, GameState.activationsThisTurn included.
type Reads = Maybe (GameEvent -> Bool)

-- | Every reader of the history in the game. Every printing, in every zone and
-- outside the game, through GameState.printings, which interns them all; a
-- token or copy spec nests inside its creator's face.
--
-- A walk over each card's derived Show rather than a hand-written traversal
-- of Card, which is where nesting gets missed. A single-word entry of
-- `historyReaders` claims an identifier it equals, and failing any such, one
-- containing it; a two-word entry claims an adjacent pair, such as a record
-- field and its value. A false match costs only a detection.
readers :: GameState -> [Reads]
readers gs =
  let single = [(word, reader) | ([word], reader) <- historyReaders]
      double = [(pair, reader) | ([first, second], reader) <- historyReaders, let pair = (first, second)]
      readersOf printing =
        let words_ = identifiers (show (Printing.card printing))
            pairs = Set.fromList (zip words_ (drop 1 words_))
            claim word = case [reader | (entry, reader) <- single, entry == word] of
              [] -> [reader | (entry, reader) <- single, entry `List.isInfixOf` word]
              exact -> exact
         in concatMap claim (Set.toList (Set.fromList words_)) <> [reader | (pair, reader) <- double, Set.member pair pairs]
   in -- The rules' own readers: Pawl.Engine.Planechase.rollCost (CR 901.9),
      -- and Pawl.Engine.Speed's once-each-turn trigger (CR 702.179d), minted
      -- for any player with a speed and limited off the AbilityTriggered log.
      [Just planarDieRolled | Planechase.isPlanechase gs]
        <> [Just abilityTriggered | any (Maybe.isJust . Player.speed) (GameState.players gs)]
        <> concatMap readersOf (Map.elems (GameState.printings gs))

-- The identifiers in a derived Show, in order.
identifiers :: String -> [String]
identifiers text = case dropWhile (not . isIdentifier) text of
  [] -> []
  rest ->
    let (word, more) = span isIdentifier rest
     in word : identifiers more
  where
    isIdentifier c = Char.isAlphaNum c || c == '_'

-- | Every construct whose engine read site consults GameState.events or
-- GameState.activationsThisTurn as history, named as Show spells it, with the
-- events that read site folds over -- through the read site's own projection
-- wherever it has one. A new reader of either field owes an entry here -- and
-- so does a construct the engine EXPANDS into one (a keyword's minted ability
-- or rider, as Pawl.Engine.Keyword builds them), since the card's Show then
-- spells only the keyword.
--
-- Read sites needing none: the readers of the CURRENT action's own events
-- (Pawl.Engine.Resolve.Effect, Pawl.Engine.Cost's reversal and mana
-- triggers, the trigger scan, the CR 704.5h watermark); readers keyed by an
-- id that has moved (Pawl.Engine.Game.arrivalsOf, revealedArriving,
-- Pawl.Engine.MoveDuration.departedIn, Pawl.Engine.Event.Trigger.entryGroup),
-- which a lap cannot move again under the same id; and
-- Pawl.Engine.Engine.beginTurnOf's fold of the casts and attacks, which a
-- priority-only lap without a zone change cannot write.
historyReaders :: [([String], Reads)]
historyReaders =
  [ -- Pawl.Engine.Count.evaluate's Scope.InHistory arm (CR 608.2i), every
    -- event Pawl.Engine.Count.snapshotView answers for some shape.
    (["InHistory"], Just inHistory),
    -- Pawl.Engine.Quantity.evaluateAgainst's arms over Pawl.Engine.Game's
    -- folds, and Pawl.Engine.Filter's atoms off Pawl.Engine.Projection.View's
    -- and Pawl.Engine.Count.playerView's folds, each by name; and, for a
    -- this-turn construct not named here, all of the history.
    (["ThisTurn"], Nothing),
    (["WasBlockedThisTurn"], via Game.blockedAttacker),
    (["DamageDealtToThisTurn"], via Game.damageDealt),
    (["AttackersDeclaredThisTurn"], Just attackerDeclared),
    (["CardsDiscardedThisTurn"], via Game.discardOf),
    -- GameState.drawsThisTurn, which `digest` keeps.
    (["CardsDrawnThisTurn"], Just (const False)),
    (["BendingsThisTurn"], Just bent),
    (["LifeGainedThisTurn"], via Game.lifeGainOf),
    (["PlayersDealtDamageThisTurn"], via Game.damagedPlayer),
    (["DamageDealtToPlayersThisTurn"], via Game.damageDealt),
    (["SpellsCastThisTurn"], via Game.castOf),
    (["TimesResolvedThisTurn"], via Game.abilityResolved),
    (["PermanentsDiedThisTurn"], via Game.diedChange),
    (["SpellsCastUsingThisTurn"], via Game.castOf),
    (["EnteredThisTurn"], via Game.enteredBattlefield),
    (["AttackedThisTurn"], Just attackerDeclared),
    (["MilledThisTurn"], Just milled),
    (["DealtDamageThisTurn"], Just (\event -> Maybe.isJust (Game.damagedObject event) || Maybe.isJust (Game.damagedPlayer event))),
    (["CrewedSourceThisTurn"], Just crewed),
    (["ConvokedSourceThisTurn"], Just convokedOrMoved),
    (["SaddledSourceThisTurn"], Just saddled),
    -- Quantity.AttackersInTheirLastTurn (Game.attackersInTheirLastTurn).
    (["AttackersInTheirLastTurn"], Just attackerDeclared),
    -- Quantity.SpellsCastBefore, EnteredFrom and WasCastFrom
    -- (Pawl.Engine.Quantity's entriesOf).
    (["SpellsCastBefore"], via Game.castOf),
    (["EnteredFrom"], via Game.enteredBattlefieldChange),
    (["WasCastFrom"], via Game.enteredBattlefieldChange),
    -- ObjectRef.FromAnywhere (Game.currentIncarnation), which follows a card
    -- through the move log.
    (["FromAnywhere"], via Game.movedChange),
    -- Pawl.Engine.Cost.candidateCostsGiven's surge, spectacle, prowl,
    -- freerunning and mayhem clauses, and
    -- Pawl.Engine.PlayerEffect.mayPlayByMayhem.
    (["Surge"], via Game.castOf),
    (["Spectacle"], Just lifeLost),
    (["Prowl"], Just dealtDamage),
    (["Freerunning"], Just dealtDamage),
    (["Mayhem"], via Game.discardOf),
    -- Pawl.Engine.PlayerEffect.prohibitsCasting's CantCastMoreThan, through
    -- Game.castsPerPlayer.
    (["CantCastMoreThan"], via Game.castOf),
    -- Pawl.Engine.Activatable.loyaltyOk (CR 606.3), every loyalty cost.
    (["Loyalty"], Just loyaltyActivated),
    -- Pawl.Engine.Event.Match's StepBegins ordinal (mainPhasesBegun) and
    -- SpellCast ordinal (castOrdinal).
    (["ordinal", "Just"], Just (\event -> stepBegan event || Maybe.isJust (Game.castOf event))),
    -- Pawl.Engine.Event.Match's declarationsOf and crewingsOf.
    (["FirstTimeEachTurn"], Just (\event -> attackerDeclared event || becameCrewed event)),
    -- Pawl.Engine.Event.withinTriggerLimit.
    (["OncePerTurn"], Just abilityTriggered),
    -- Pawl.Engine.Saga.readAheadRestricted (CR 702.155a).
    (["ReadAhead"], via Game.enteredBattlefield),
    -- Pawl.Engine.Coin.statedFor's flipsThisTurn.
    (["firstEachTurn", "True"], Just coinFlipped),
    -- Pawl.Engine.PlayerEffect.firstActivation, over activationsThisTurn.
    (["onlyFirst", "Just"], Nothing),
    -- Keyword expansions, whose readers the printed keyword does not spell:
    -- Pawl.Engine.Keyword.storm's Quantity.SpellsCastBefore (CR 702.40a),
    -- Keyword.gravestorm's Quantity.PermanentsDiedThisTurn (CR 702.69a), and
    -- Keyword.printedRiders' Boast arm, a Count over Filter.AttackedThisTurn
    -- (CR 702.142a). Separate entries, the walk being case-sensitive.
    (["Storm"], via Game.castOf),
    (["Gravestorm"], via Game.diedChange),
    (["Boast"], Just attackerDeclared),
    -- Pawl.Engine.MoveDuration.hasHappened's CR 610.3a/b crowning look-back.
    (["UntilAnOpponentBecomesTheMonarch"], Just becameMonarch)
  ]
  where
    via :: (GameEvent -> Maybe a) -> Reads
    via projection = Just (Maybe.isJust . projection)

-- The events a Scope.InHistory fold can answer for.
inHistory :: GameEvent -> Bool
inHistory event = case event of
  GameEvent.Moved {} -> True
  GameEvent.CardArrived {} -> True
  GameEvent.LeftTheGame {} -> True
  GameEvent.SpellCast {} -> True
  _ -> False

becameMonarch :: GameEvent -> Bool
becameMonarch event = case event of
  GameEvent.BecameMonarch {} -> True
  _ -> False

attackerDeclared :: GameEvent -> Bool
attackerDeclared event = case event of
  GameEvent.AttackerDeclared {} -> True
  _ -> False

dealtDamage :: GameEvent -> Bool
dealtDamage event = case event of
  GameEvent.DamageDealt {} -> True
  _ -> False

bent :: GameEvent -> Bool
bent event = case event of
  GameEvent.PlayerActed acted -> Set.member (PlayerActed.action acted) Game.bendingActions
  _ -> False

milled :: GameEvent -> Bool
milled event = case event of
  GameEvent.Milled {} -> True
  _ -> False

crewed :: GameEvent -> Bool
crewed event = case event of
  GameEvent.Crewed {} -> True
  _ -> False

becameCrewed :: GameEvent -> Bool
becameCrewed event = case event of
  GameEvent.BecameCrewed {} -> True
  _ -> False

-- Pawl.Engine.Count.convokedThisTurn follows the convoked spell
-- onto the battlefield through the move log.
convokedOrMoved :: GameEvent -> Bool
convokedOrMoved event = case event of
  GameEvent.Convoked {} -> True
  GameEvent.Moved {} -> True
  _ -> False

saddled :: GameEvent -> Bool
saddled event = case event of
  GameEvent.Saddled {} -> True
  _ -> False

lifeLost :: GameEvent -> Bool
lifeLost event = case event of
  GameEvent.LifeLost {} -> True
  _ -> False

loyaltyActivated :: GameEvent -> Bool
loyaltyActivated event = case event of
  GameEvent.LoyaltyAbilityActivated {} -> True
  _ -> False

stepBegan :: GameEvent -> Bool
stepBegan event = case event of
  GameEvent.StepBegan {} -> True
  _ -> False

abilityTriggered :: GameEvent -> Bool
abilityTriggered event = case event of
  GameEvent.AbilityTriggered {} -> True
  _ -> False

coinFlipped :: GameEvent -> Bool
coinFlipped event = case event of
  GameEvent.CoinFlipped {} -> True
  _ -> False

planarDieRolled :: GameEvent -> Bool
planarDieRolled event = case event of
  GameEvent.PlanarDieRolled {} -> True
  _ -> False

-- | CR 732.3: the game choices `pid`, asked at `gs` (digested as `here`), may
-- not make, so a fragmented loop does not continue: the actions refused
-- outright, and the activations refused as completed with. Both empty unless
-- `here` repeats a state this loop has seen, nothing in the game reads the
-- history the loop appended since (`lapIsRead`), and `pid` is the player the
-- rule names.
--
-- "Involved in the loop" is the players who took a non-Pass action since the
-- state FIRST occurred: a shorter loop nested inside a longer one through the
-- same state (a no-op lap by one player) must not hide the longer one's
-- players. Forbidden is every choice `pid` made at ANY prior occurrence, not
-- only the last, so A, B, A, B through one state is refused too: a
-- `choiceless` action as a whole, and an activation, a mana ability's among
-- them (CR 605.3a), as it was completed -- announced and paid -- so aiming it
-- elsewhere (CR 601.2c) or paying it another way (CR 601.2g/h) is still a
-- choice to make. A choice made later in the lap -- as the object
-- resolves (CR 608.2d), or for a trigger it causes -- is a game choice of its
-- own, and leaves this one as it was: CR 732.3's example refuses "activating
-- that creature's ability again" outright. Pass never is (CR 732.5). Pawl.FragmentedSpec's
-- control case is the board where the nesting happens, its Grim Poppet case
-- the announcement, its Freed from the Real cases the payment and the mana
-- ability, and its Fatestitcher case a choice at resolution.
forbidden :: StateDigest -> GameState -> PlayerId -> LoopTrail -> (Set.Set Action, Set.Set (Action, Completion.Completion))
forbidden here gs pid loopTrail =
  case Map.findWithDefault [] here (LoopTrail.seen loopTrail) of
    [] -> (Set.empty, Set.empty)
    occurrences ->
      let choices = LoopTrail.choices loopTrail
          firstSeen = minimum occurrences
          acted (_, _, action, _) = action /= Action.Pass
          involved = Set.fromList [who | (_, who, _, _) <- filter acted (Foldable.toList (Seq.drop firstSeen choices))]
          named = List.find (`Set.member` involved) (Game.turnOrderFrom (GameState.activePlayer gs) gs)
          made = [(action, completed) | (_, who, action, completed) <- Maybe.mapMaybe (`Seq.lookup` choices) occurrences, who == pid]
          taken = Set.fromList [action | (action, _) <- made, choiceless action]
          completedWith = Set.fromList [(action, completion) | (action, Just completion) <- made]
          unread = case Seq.lookup firstSeen choices of
            Just (there, _, _, _) -> not (lapIsRead there gs)
            Nothing -> False
       in if named == Just pid && unread then (taken, completedWith) else (Set.empty, Set.empty)

-- | Is `action` the whole of the game choice (CR 732.1), so refusing it
-- refuses only the choice that continued the loop? An activation with no
-- target, a single mode, no X and no cost but nothing to pay; never Pass (CR
-- 732.5). Refused from the menu, where an activation with more to announce or
-- pay is refused by how it was completed instead (`forbidden`).
choiceless :: Action -> Bool
choiceless action = case action of
  Action.Activate _ ability ->
    let modal = ActivatedAbility.modal ability
        cost = ActivatedAbility.cost ability
     in all (Map.null . Mode.targetSlots) (Modal.modes modal)
          && Seq.length (Modal.modes modal) == 1
          && Modal.selection modal == ModeSelection.ChooseExactly 1
          && null (ActivatedAbility.maximumX ability)
          && maybe True (null . ManaCost.unwrap) (Cost.mana cost)
          && null (Cost.components cost)
  _ -> False

-- | CR 601.2g/h: a payment as the game choice it completes, read off the
-- state `gs` it left -- the mana abilities activated, the mana spent, the
-- objects each component took -- digested, less `paidFor`, the ability object
-- it paid for, whose id is new every lap. The same choices leave the same
-- state; different ones leaving it too are indistinguishable. A difference only
-- the history shows is one `lapIsRead` finds no reader of.
paid :: Maybe ObjectId.ObjectId -> GameState -> StateDigest
paid paidFor gs = case paidFor of
  Nothing -> digest gs
  Just oid ->
    digest
      gs
        { GameState.objects = Map.delete oid (GameState.objects gs),
          GameState.stack = filter (/= oid) (GameState.stack gs)
        }

-- | Note that `pid`, asked at `here`, chose `action`. Held as pending until
-- the next prompt, since an action CR 733.1 reversed -- a refused
-- activation among them -- leaves the game in the state it was taken in and
-- never happened. A REGRESSION FENCE: the Grim Poppet case reverses one, but
-- counting it changes nothing that case refuses, so no test observes the
-- hold; it keeps a reversed attempt from counting its player as involved.
record :: StateDigest -> PlayerId -> Action -> LoopTrail -> LoopTrail
record here pid action loopTrail = loopTrail {LoopTrail.pending = Just (here, pid, action, Nothing)}

-- | Note what the pending activation was completed with, once it has been.
complete :: Maybe Completion.Completion -> LoopTrail -> LoopTrail
complete completed loopTrail =
  loopTrail {LoopTrail.pending = fmap (\(there, pid, action, _) -> (there, pid, action, completed)) (LoopTrail.pending loopTrail)}

-- | Commit the pending choice, unless the game is still in the state it was
-- made in. Both functions above take a trail settled against `here`.
settle :: StateDigest -> LoopTrail -> LoopTrail
settle here loopTrail = case LoopTrail.pending loopTrail of
  Nothing -> loopTrail
  Just (there, pid, action, completed)
    | there == here -> loopTrail {LoopTrail.pending = Nothing}
    | otherwise ->
        let at = Seq.length (LoopTrail.choices loopTrail)
         in loopTrail
              { LoopTrail.choices = LoopTrail.choices loopTrail Seq.|> (there, pid, action, completed),
                LoopTrail.seen = Map.insertWith (<>) there [at] (LoopTrail.seen loopTrail),
                LoopTrail.pending = Nothing
              }
