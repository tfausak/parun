-- | CR 733.3: a fragmented loop, where each player involved takes an
-- independent action and the game returns to a state it was in before. The
-- active player, or the first involved player in turn order from them, must
-- then make a different game choice -- at the priority grain CR 733.1 names,
-- a different action -- so the loop does not continue.
--
-- Not a choice made for anyone: the rule narrows the named player's menu, and
-- CR 733.5 keeps Pass on it.
--
-- UNDER-DETECTION is the safe direction throughout. A state this module fails
-- to recognise as a repeat leaves the menu as it was, so every approximation
-- here errs towards seeing no loop.
module Parun.Engine.Fragmented where

import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Monoid as Monoid
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Numeric.Natural as Natural
import qualified Parun.Engine.Count as Count
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Interchangeable.Mentions as Mentions
import qualified Parun.Engine.Keyword as Keyword
import qualified Parun.Engine.MoveDuration as MoveDuration
import qualified Parun.Engine.Planechase as Planechase
import qualified Parun.Engine.Projection as Projection
import qualified Parun.Extra.Int as Int
import qualified Parun.Types.AbilityWasActivated as AbilityWasActivated
import qualified Parun.Types.Acquisition as Acquisition
import Parun.Types.Action (Action)
import qualified Parun.Types.Action as Action
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActiveCopy as ActiveCopy
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Completion as Completion
import qualified Parun.Types.ContinuousEffect as ContinuousEffect
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CounterLink as CounterLink
import qualified Parun.Types.DelayedTrigger as DelayedTrigger
import qualified Parun.Types.EntryLink as EntryLink
import qualified Parun.Types.EventGroup as EventGroup
import qualified Parun.Types.ExileLink as ExileLink
import Parun.Types.GameEvent (GameEvent)
import qualified Parun.Types.GameEvent as GameEvent
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.HistoryRead as HistoryRead
import qualified Parun.Types.Keyword as Keyword.Type
import qualified Parun.Types.LastKnown as LastKnown
import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.LoggedEvent as LoggedEvent
import Parun.Types.LoopTrail (LoopTrail)
import qualified Parun.Types.LoopTrail as LoopTrail
import qualified Parun.Types.Mana as Mana
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Player as Player
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.Printing as Printing
import qualified Parun.Types.PrintingId as PrintingId
import Parun.Types.StateDigest (StateDigest)
import qualified Parun.Types.StateDigest as StateDigest
import qualified Parun.Types.StickerPlacement as StickerPlacement
import qualified Parun.Types.Timestamp as Timestamp
import qualified Text.Read as Read

-- | The game state as CR 733.3 compares it: the whole record, by its derived
-- Show, less the fields below, with every object id and timestamp renumbered
-- by rank. A RECORD UPDATE rather than a field list, so a field added later is
-- compared by default and can only ever prevent a detection --
-- Parun.Engine.Interchangeable.objects' posture, whole-Object Eq less the
-- timestamp.
--
-- Renumbered because a zone change makes a new object (CR 400.7) that no card
-- or player can tell from the old one but by what the history says of it, and
-- a stamp is read only for its order (CR 613.7). By rank, so every map and set
-- keyed by either keeps its order, and the renaming is the identity on two
-- states that hold the same ids. A rank is relative to what the state holds,
-- so a loop is caught only from the lap whose new objects rank as the last
-- lap's did -- an under-detection. docs/decisions.md, "When a re-created
-- object is the same game state".
--
-- Dropped as bookkeeping no card reads: the id, timestamp, printing and event
-- group supplies; CR 104.4b's `lastChoice` and `loopInvolvement`; CR 733.3's
-- own `repeatPicks`, which a RepeatIf's runs compare digests to fill; CR
-- 734.1's `undone`, which only a client reads; the grow-only printing
-- interning; and the scan state keyed off the log
-- (`scannedThrough`, `damageScannedThrough`, `battlefieldWhenTriggered`,
-- `controlSample`, `stackedIn`). `lastKnown` and `stackArchive` are keyed by
-- ids that have left (CR 400.7), so only the entries of the ids the rest of
-- the state holds are compared.
--
-- Dropped as history a card CAN read: `events` and `activationsThisTurn`.
-- Compared, no state could recur, since every action appends to both; so they
-- ride along uncompared, and `lapIsRead` asks whether anything in the game
-- reads what the loop appended to them.
--
-- Trimmed to what its sources read: `counteredWith`, each link compared only
-- where its source can read it (CR 607.1, `readsOwnCounterLinks`). A Grim
-- Poppet's lap beside a Cyclopean Tomb still recurs; the Tomb's own does not.
digest :: GameState -> StateDigest
digest gs =
  let (effects, objects, reacquire) = canonicalStamps gs
      trimmed =
        gs
          { GameState.events = Seq.empty,
            GameState.activationsThisTurn = Seq.empty,
            GameState.counteredWith = Map.filter (not . Set.null) (fmap (Set.map (\link -> link {CounterLink.acquisition = reacquire (CounterLink.acquisition link)}) . Set.filter (readsOwnCounterLinks gs . CounterLink.source)) (GameState.counteredWith gs)),
            -- Only a countdown shield's key is read, and its row, compared here, shrinks as it grows.
            GameState.damagePreventedBy = Map.empty,
            GameState.nextObjectId = ObjectId.MkObjectId 0,
            GameState.nextTimestamp = Timestamp.MkTimestamp 0,
            GameState.nextPrintingId = PrintingId.MkPrintingId 0,
            GameState.nextEventGroup = EventGroup.MkEventGroup 0,
            GameState.eventGroupDepth = 0,
            GameState.lastChoice = Timestamp.MkTimestamp 0,
            GameState.loopInvolvement = Map.empty,
            GameState.repeatPicks = Nothing,
            GameState.undone = Map.empty,
            GameState.printings = Map.empty,
            GameState.printingIds = Map.empty,
            GameState.scannedThrough = 0,
            GameState.damageScannedThrough = 0,
            GameState.boardAfterEvent = Map.empty,
            GameState.boardBeforeEvent = Map.empty,
            GameState.battlefieldWhenTriggered = Map.empty,
            GameState.controlSample = Map.empty,
            GameState.boardAtControlSample = Nothing,
            GameState.heldBoards = [],
            GameState.lastKnown = Map.empty,
            GameState.stackArchive = Map.empty,
            GameState.cardsPlayed = Map.empty,
            GameState.stackedIn = Map.empty,
            -- One value for a whole turn, and the digest keeps turnNumber.
            GameState.permanentsAsTurnBegan = Nothing,
            -- Canonical rather than dropped, so CR 733.3's own example recurs,
            -- and a loop that moves a counter back.
            GameState.continuousEffects = effects,
            GameState.objects = objects,
            GameState.exiledWith = fmap (\link -> link {ExileLink.acquisition = reacquire (ExileLink.acquisition link)}) (GameState.exiledWith gs),
            GameState.enteredWith = fmap (\link -> link {EntryLink.acquisition = reacquire (EntryLink.acquisition link)}) (GameState.enteredWith gs),
            -- Canonical rather than dropped: a payment leaves an empty pool
            -- behind where there was no entry, and no card tells the two apart.
            GameState.manaPool = Map.filter (not . null . Mana.unwrap) (GameState.manaPool gs)
          }
      shown = show trimmed
      held = Set.fromList (fmap ObjectId.MkObjectId (Map.keys (ranked objectIdTag shown)))
      -- What the log says of each held id, as the readers keyed by one ask it
      -- (`readers`), so a renamed id is the same object only where the
      -- history answers for it as for the one it renames.
      told oid = (Game.arrivalsOf oid gs, Maybe.isJust (Game.entryGroup oid gs), Maybe.isJust (MoveDuration.departedIn oid gs), Count.revealedInPlace gs oid, Count.revealedArriving gs oid)
      departed = show (Map.restrictKeys (GameState.lastKnown gs) held, Map.restrictKeys (GameState.stackArchive gs) held, Map.restrictKeys (GameState.cardsPlayed gs) held, fmap told (Set.toAscList held))
      rendered = shown <> departed
      ids = ranked objectIdTag rendered
   in StateDigest.MkStateDigest
        { StateDigest.unwrap = trimmed,
          StateDigest.canonical = renumber ids (ranked timestampTag rendered) rendered,
          StateDigest.objectRanks = ids,
          StateDigest.events = GameState.events gs,
          StateDigest.activations = GameState.activationsThisTurn gs
        }

-- | CR 607.1 / 608.2h: can `source`, live or gone, read the counters its own
-- effects moved? Asked of the cards representing it, its projection (CR 613.1:
-- a copy effect, a full text, a grant), else its last known characteristics
-- and copiable values, and the delayed triggers it made (CR 603.7). Erring
-- towards yes, the safe direction.
readsOwnCounterLinks :: GameState -> ObjectId.ObjectId -> Bool
readsOwnCounterLinks gs source =
  let projected = Monoid.getAny . Mentions.projectedCharacteristicsNames Mentions.readsCounterLinks
   in any (Monoid.getAny . Mentions.cardNames Mentions.readsCounterLinks) (Game.cardsOfWithLastKnown source gs)
        || or (Game.liveOrLastKnown (\_ -> projected (Projection.project source gs)) (\known -> projected (LastKnown.characteristics known) || projected (LastKnown.copiable known)) source gs)
        || any (\entry -> DelayedTrigger.source entry == source && Monoid.getAny (Mentions.delayedTriggerNames Mentions.readsCounterLinks entry)) (GameState.delayedTriggers gs)

-- How the derived Show renders an object id and a timestamp, up to the
-- number.
objectIdTag :: String
objectIdTag = "MkObjectId {unwrap = "

timestampTag :: String
timestampTag = "MkTimestamp {unwrap = "

-- Each number `tag` precedes in `rendered`, by its rank among them.
ranked :: String -> String -> Map.Map Natural.Natural Int
ranked tag rendered = Map.fromDistinctAscList (zip (Set.toAscList (Set.fromList (tagged tag rendered))) [0 ..])

-- Every number `tag` precedes in `rendered`.
tagged :: String -> String -> [Natural.Natural]
tagged tag rendered = case rendered of
  [] -> []
  _ : rest -> case List.stripPrefix tag rendered of
    Just after ->
      let (digits, more) = span Char.isDigit after
       in maybe id (:) (Read.readMaybe digits) (tagged tag more)
    Nothing -> tagged tag rest

-- | `rendered` with each object id and timestamp written as its rank in `ids`
-- and `stamps`, and one neither ranks marked as raw, so it matches no rank.
renumber :: Map.Map Natural.Natural Int -> Map.Map Natural.Natural Int -> String -> String
renumber ids stamps rendered = case rendered of
  [] -> []
  c : rest -> case (List.stripPrefix objectIdTag rendered, List.stripPrefix timestampTag rendered) of
    (Just after, _) -> objectIdTag <> number ids after
    (_, Just after) -> timestampTag <> number stamps after
    _ -> c : renumber ids stamps rest
  where
    number ranks after =
      let (digits, more) = span Char.isDigit after
          written = case Read.readMaybe digits >>= (`Map.lookup` ranks) of
            Just rank -> show rank
            Nothing -> '?' : digits
       in written <> renumber ids stamps more

-- | A game choice made in the state `here` digests, as CR 733.3 compares it:
-- its object ids renumbered as `here`'s are (`digest`). So the same choice of a
-- re-created object, made in a recurrence of `here`, is the same choice.
choiceKey :: (Show choice) => StateDigest -> choice -> String
choiceKey here = renumber (StateDigest.objectRanks here) Map.empty . show

-- | CR 733.3 over the stamps an action leaves behind -- the stored continuous
-- effects (CR 611.2a) and the counters' (CR 613.7c) -- as the game can tell
-- them apart. A row is dropped where a later one from the same source, over
-- the same fixed set (CR 611.2c) and ending with it, `erases` it, which leaves
-- nothing it did standing (CR 613.7); a counter stamp, where the object has no
-- counters of its kind, which leaves it inert. The rest stamped after every
-- other stamp CR 613.7 orders them against (`layeredStamps`) are then
-- restamped in order from just above the latest of those, since only their
-- order is ever read (`digest` drops GameState.nextTimestamp).
--
-- Parun.FragmentedSpec's Mist Dragon cases prove both halves for the rows, its
-- Arcanum Wings case the floor, and its Grim Poppet case both for the
-- counters. Also answers the restamping of an acquisition, for the links
-- keyed by one (GameState.exiledWith, GameState.enteredWith).
canonicalStamps :: GameState -> ([ContinuousEffect.ContinuousEffect Card.Card], Map.Map ObjectId.ObjectId Object.Object, Acquisition.Acquisition -> Acquisition.Acquisition)
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
      -- stored copy row's stamp is under the floor, so a stored result or a
      -- choice keyed by one is left as it stands. A REGRESSION FENCE: no test
      -- loops a no-duration copy.
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
        fmap (\obj -> obj {Object.counterTimestamps = fmap restamp (Object.counterTimestamps obj), Object.acquisition = reacquire (Object.acquisition obj), Object.storedResults = Map.mapKeysWith (Map.unionWith (+)) reacquire (Object.storedResults obj), Object.chosenColors = Map.mapKeys reacquire (Object.chosenColors obj), Object.chosenSubtype = Map.mapKeys reacquire (Object.chosenSubtype obj), Object.chosenNames = Map.mapKeys reacquire (Object.chosenNames obj), Object.chosenPlayers = Map.mapKeys reacquire (Object.chosenPlayers obj), Object.chosenNumber = Map.mapKeys reacquire (Object.chosenNumber obj)}) objects,
        reacquire
      )

-- | Does `later`, applied after `earlier` to the same objects, leave nothing
-- `earlier` did? A keyword removal (CR 613.1f) erases an earlier removal of
-- keywords it `takes` all of, and an earlier grant of one it takes: a
-- protection grant is rebaked (Parun.Engine.Keyword.grantedBy), so a removal of
-- one keyword erases only a grant of a familyless one, where a family removal
-- takes whatever the rebake made of it. A grant erases nothing, two grants of
-- a keyword counting twice (Parun.Engine.Projection.applyModification). An
-- all-abilities removal erases every earlier row `wiped` names.
--
-- A later identical type SET erases nothing: under Opalescence the earlier
-- one is what its grant depends on (CR 613.8a), so dropping it reorders the
-- grant (data/scenarios/projection's second Soul Sculptor activation).
--
-- Parun.FragmentedSpec's Mist Dragon cases prove a removal of one keyword
-- erasing a removal and a grant of it, its Shadowspear case a family removal
-- erasing another, and its Synthetic Hushing Adept case an all-abilities
-- removal erasing another. A family removal erasing a removal of one keyword
-- or a grant, the family guard, and an all-abilities removal erasing any
-- other row, are a regression fence: no test loops them.
erases :: Modification.Modification ability -> Modification.Modification ability -> Bool
erases later earlier = case (later, earlier) of
  (Modification.LoseAllAbilities, _) -> wiped earlier
  (_, Modification.LoseKeyword keyword) -> takes later keyword
  (Modification.LoseKeywordFamily g, Modification.LoseKeywordFamily f) -> g == f
  (Modification.LoseKeyword lost, Modification.GainKeyword keyword) -> lost == keyword && Maybe.isNothing (Keyword.familyOf keyword)
  (_, Modification.GainKeyword keyword) -> takes later keyword
  _ -> False

-- | Is all of what this layer-6 row writes emptied by a later all-abilities
-- removal (Parun.Engine.Projection.applyModification's LoseAllAbilities arm)?
-- Every removal, and a grant whose list that arm empties. Not a quoted
-- ability's grant, whose kind this cannot see, and not CR 702.184c's station
-- toughness, which that arm leaves standing.
wiped :: Modification.Modification ability -> Bool
wiped m = case m of
  Modification.LoseAllAbilities -> True
  Modification.LoseNamedAbility _ -> True
  Modification.LoseKeyword _ -> True
  Modification.LoseKeywordFamily _ -> True
  Modification.LoseEnchant _ -> True
  Modification.GainKeyword _ -> True
  Modification.GainKeywordAtManaCost _ -> True
  Modification.GainEnchant _ -> True
  Modification.GainCastingPermission _ -> True
  _ -> False

-- | Does `removal` take `keyword` away (CR 613.1f)? A family removal takes
-- every keyword of the family (CR 702.11e, 702.14a); anything else, none.
takes :: Modification.Modification ability -> Keyword.Type.Keyword -> Bool
takes removal keyword = case removal of
  Modification.LoseKeyword lost -> lost == keyword
  Modification.LoseKeywordFamily f -> Keyword.familyOf keyword == Just f
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

-- | CR 733.3's example makes "nothing in the game cares how many times an
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
      let wrote reading = case reading of
            HistoryRead.Activations -> not (Seq.null activations)
            _ -> any (records reading . LoggedEvent.event) events
       in any wrote (readers gs)
    _ -> True
  where
    appended :: (Eq a) => Seq.Seq a -> Seq.Seq a -> Maybe (Seq.Seq a)
    appended before after =
      let (prefix, rest) = Seq.splitAt (Seq.length before) after
       in if prefix == before then Just rest else Nothing

-- | Every reader of the history in the game, as what it reads. Every
-- printing, in every zone and outside the game, through GameState.printings,
-- which interns them all, as Parun.Engine.Interchangeable.Mentions classifies
-- it; a token or copy spec nests inside its creator's face.
--
-- Read sites needing no classification: the readers of the CURRENT action's
-- own events (Parun.Engine.Resolve.Effect, Parun.Engine.Cost's reversal and mana
-- triggers, the trigger scan, the CR 704.5h watermark); readers keyed by an
-- id (Parun.Engine.Game.arrivalsOf, entryGroup,
-- Parun.Engine.Count.revealedInPlace, revealedArriving,
-- Parun.Engine.MoveDuration.departedIn), whose answers `digest` compares, or
-- that mints a new one (Parun.Engine.Event.forgetShown); and
-- Parun.Engine.PlayerView's witnessed log, which no rule reads.
-- Parun.Engine.Engine.beginTurnOf's fold of the casts, damage and attacks
-- feeds readers classified here, and CR 732.2a's day and night, the rules'
-- own reader of the casts.
readers :: GameState -> Set.Set HistoryRead.HistoryRead
readers gs =
  -- The rules' own readers: Parun.Engine.Planechase.rollCost (CR 901.9),
  -- Parun.Engine.Speed's once-each-turn trigger (CR 702.179d), minted for any
  -- player with a speed and limited off the AbilityTriggered log, and
  -- Parun.Engine.Daytime's untap-step check of the casts (CR 732.2a), once it
  -- is day or night.
  Set.fromList ([HistoryRead.PlanarRolls | Planechase.isPlanechase gs] <> [HistoryRead.Triggers | any (Maybe.isJust . Player.speed) (GameState.players gs)] <> [HistoryRead.Casts | Maybe.isJust (GameState.daytime gs)])
    <> foldMap (Mentions.cardNames historyReads . Printing.card) (GameState.printings gs)

-- The history question, asked of every leaf.
historyReads :: Mentions.Asking (Set.Set HistoryRead.HistoryRead)
historyReads =
  Mentions.MkAsking
    { Mentions.names = const Set.empty,
      Mentions.context = Set.empty,
      Mentions.keyed = Set.empty,
      Mentions.history = Set.singleton,
      Mentions.prevention = Set.empty,
      Mentions.counterLinks = Set.empty,
      Mentions.melded = id
    }

-- | Does this logged event record part of what `reading` reads? Through the read
-- site's own projection wherever it has one. GameState.activationsThisTurn
-- records the activations that read reads, mana abilities included, so
-- GameEvent.AbilityActivated does not.
records :: HistoryRead.HistoryRead -> GameEvent -> Bool
records reading event = case reading of
  HistoryRead.Activations -> False
  HistoryRead.Attacks -> attackerDeclared event
  HistoryRead.Acts acts -> actedAmong acts event
  HistoryRead.Blockers -> blocked event
  HistoryRead.Blocks -> Maybe.isJust (Game.blockedAttacker event)
  HistoryRead.Casts -> Maybe.isJust (Game.castOf event)
  HistoryRead.CoinFlips -> coinFlipped event
  HistoryRead.Convokes -> convoked event
  HistoryRead.Crews -> crewed event
  HistoryRead.Damage -> dealtDamage event
  HistoryRead.Deaths -> Maybe.isJust (Game.diedChange event)
  HistoryRead.Discards -> Maybe.isJust (Game.discardOf event)
  HistoryRead.Entries -> Maybe.isJust (Game.enteredBattlefieldChange event)
  HistoryRead.LifeGains -> Maybe.isJust (Game.lifeChangeOf LifeDirection.Gained event)
  HistoryRead.LifeLosses -> Maybe.isJust (Game.lifeChangeOf LifeDirection.Lost event)
  HistoryRead.LoyaltyActivations -> loyaltyActivated event
  HistoryRead.MonarchChanges -> becameMonarch event
  HistoryRead.Mills -> milled event
  HistoryRead.Moves -> moved event
  HistoryRead.PlanarRolls -> planarDieRolled event
  HistoryRead.Resolutions -> Maybe.isJust (Game.abilityResolved event)
  HistoryRead.Saddles -> saddled event
  HistoryRead.StepBegins -> stepBegan event
  HistoryRead.Triggers -> abilityTriggered event

-- The zone changes, and a player leaving the game: what a Scope.InHistory
-- fold can answer for, bar the casts.
moved :: GameEvent -> Bool
moved event = case event of
  GameEvent.Moved {} -> True
  GameEvent.CardArrived {} -> True
  GameEvent.LeftTheGame {} -> True
  _ -> False

becameMonarch :: GameEvent -> Bool
becameMonarch event = case event of
  GameEvent.BecameMonarch {} -> True
  _ -> False

attackerDeclared :: GameEvent -> Bool
attackerDeclared event = case event of
  GameEvent.AttackerDeclared {} -> True
  _ -> False

blocked :: GameEvent -> Bool
blocked event = case event of
  GameEvent.BlocksDeclared {} -> True
  _ -> False

dealtDamage :: GameEvent -> Bool
dealtDamage event = case event of
  GameEvent.DamageDealt {} -> True
  _ -> False

actedAmong :: Set.Set PlayerAction.PlayerAction -> GameEvent -> Bool
actedAmong acts event = case event of
  GameEvent.PlayerActed acted -> Set.member (PlayerActed.action acted) acts
  _ -> False

milled :: GameEvent -> Bool
milled event = case event of
  GameEvent.Milled {} -> True
  _ -> False

-- A creature crewing a vehicle, and a vehicle becoming crewed.
crewed :: GameEvent -> Bool
crewed event = case event of
  GameEvent.Crewed {} -> True
  GameEvent.BecameCrewed {} -> True
  _ -> False

convoked :: GameEvent -> Bool
convoked event = case event of
  GameEvent.Convoked {} -> True
  _ -> False

saddled :: GameEvent -> Bool
saddled event = case event of
  GameEvent.Saddled {} -> True
  _ -> False

loyaltyActivated :: GameEvent -> Bool
loyaltyActivated event = case event of
  GameEvent.AbilityActivated a -> AbilityWasActivated.loyalty a
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

-- | CR 733.3: the game choices `pid`, asked at `gs` (digested as `here`), may
-- not make, so a fragmented loop does not continue: the actions refused
-- outright, and the activations and casts refused as completed with, each
-- as `choiceKey` and `completionKey` write it. Both empty unless
-- `here` repeats a state this loop has seen, nothing in the game reads the
-- history the loop appended since (`lapIsRead`), and `pid` is the player the
-- rule names.
--
-- "Involved in the loop" is the players who took a non-Pass action (CR 733.1,
-- 733.5) since the state FIRST occurred: a shorter loop nested inside a longer
-- one through the same state (a no-op lap by one player) must not hide the
-- longer one's players. Forbidden is every choice `pid` made at ANY prior
-- occurrence, not only the last, each having led back here: CR 733.3's "so the
-- loop does not continue" refuses A, B, A, B too. A `choiceless` action is
-- refused as a whole, by CR 733.3's example ("anything other than activating
-- that creature's ability again"), and an activation, a mana ability's among
-- them (CR 605.3a), or a cast, as it was completed -- announced and paid -- so
-- aiming it elsewhere (CR 601.2c) or paying it another way (CR 601.2g/h) is
-- still a choice to make. A choice made later in the lap -- as the object
-- resolves (CR 608.2d), or for a trigger it causes -- is a game choice of its
-- own, and leaves this one as it was. Pass never is (CR 733.5). Parun.FragmentedSpec's
-- control case is the board where the nesting happens, its Grim Poppet case
-- the announcement, its Freed from the Real cases the payment and the mana
-- ability, its Fatestitcher case a choice at resolution, and its Blinking
-- Spirit case a cast of a re-created object (CR 400.7).
-- docs/decisions.md, "What a fragmented loop forbids, and who is involved".
forbidden :: StateDigest -> GameState -> PlayerId -> LoopTrail -> (Set.Set String, Set.Set (String, (Maybe String, StateDigest)))
forbidden here gs pid loopTrail =
  case Map.findWithDefault [] here (LoopTrail.seen loopTrail) of
    [] -> (Set.empty, Set.empty)
    occurrences ->
      let choices = LoopTrail.choices loopTrail
          firstSeen = minimum occurrences
          acted (_, _, action, _) = action /= Action.Pass
          involved = Set.fromList [who | (_, who, _, _) <- filter acted (Foldable.toList (Seq.drop firstSeen choices))]
          named = List.find (`Set.member` involved) (Game.turnOrderFrom (GameState.activePlayer gs) gs)
          made = [(there, action, completed) | (there, who, action, completed) <- Maybe.mapMaybe (`Seq.lookup` choices) occurrences, who == pid]
          taken = Set.fromList [choiceKey there action | (there, action, _) <- made, choiceless action]
          completedWith = Set.fromList [(choiceKey there action, completionKey there completion) | (there, action, Just completion) <- made]
          unread = case Seq.lookup firstSeen choices of
            Just (there, _, _, _) -> not (lapIsRead there gs)
            Nothing -> False
       in if named == Just pid && unread then (taken, completedWith) else (Set.empty, Set.empty)

-- | What an activation or a cast made in the state `here` digests was
-- completed with, as CR 733.3 compares it: the announcement renumbered as
-- `here`'s ids are (`choiceKey`), and the payment, digested already.
completionKey :: StateDigest -> Completion.Completion -> (Maybe String, StateDigest)
completionKey here completion = (fmap (choiceKey here) (Completion.announcement completion), Completion.paid completion)

-- | Is `action` the whole of the game choice (CR 733.1), so refusing it
-- refuses only the choice that continued the loop? An activation with no
-- target, a single mode, no X and no cost but nothing to pay; never Pass (CR
-- 733.5). Refused from the menu, where an activation with more to announce or
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
-- the next prompt, since an action CR 734.1 reversed -- a refused
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
