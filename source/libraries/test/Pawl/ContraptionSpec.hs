{-# LANGUAGE GADTs #-}

-- Covers: Unstable's Contraptions, from the Unstable FAQ since CR 701.45a leaves
-- them out of the rules -- Pawl.Engine.Contraption's assemble and crank,
-- Effect.Assemble, ReplacementEffect.AssembleR, the Contraption deck
-- (SideDeck.Contraption), the sprockets (Designation.Sprocket1..3) and the
-- scrapyard (Event.toJunkyard).
--
-- First Pick ("Assemble a Contraption") and Wrench-Rigger ("it assembles a
-- Contraption") are the assemblers, Arms Depot ("Whenever you crank this
-- Contraption, put two +1/+1 counters on target creature") the Contraption, and
-- Steamflogger Boss the black-bordered card that doubles a Rigger's assembly.
module Pawl.ContraptionSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.Engine.Contraption as Contraption
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Event as Event
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Projection as Projection
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Sba as Sba
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Engine.Stack as Stack
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.AnyNumberOf as AnyNumberOf
import qualified Pawl.Types.BeginningStep as BeginningStep
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.Designation as Designation
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Object as Object
import Pawl.Types.ObjectId (ObjectId)
import qualified Pawl.Types.Phase as Phase
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Printing as Printing
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.SideDeck as SideDeck
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Contraption" $ do
  assembleSpec s registry
  crankSpec s registry
  bossSpec s registry
  scrapyardSpec s registry
  newGameSpec s registry

armsDepot :: CardName.CardName
armsDepot = CardName.MkCardName (Text.pack "Arms Depot")

-- `pid` brings `n` Arms Depots as a Contraption deck, and nothing else.
withDepots :: Printing.Printing -> Natural -> PlayerId -> GameState.GameState -> GameState.GameState
withDepots depot n pid gs =
  S.runPure S.identityAnswer gs (Setup.createDeck pid (Deck.fromCards Map.empty) {Deck.sideDecks = Map.singleton SideDeck.Contraption (Map.singleton depot n)})

-- What the answerer below was asked.
data Asked = MkAsked
  { sprocketsOffered :: [[Designation.Designation]],
    cranksOffered :: [[ObjectId]]
  }

-- Run `game`, answering each sprocket prompt from `sprockets` in turn (the
-- third once they run out), each crank prompt with `crank` applied to what was
-- offered, every target slot with `target` alone, and everything else as
-- S.identityAnswer does. Answers the final board and what was asked.
driving :: [Designation.Designation] -> ([ObjectId] -> [ObjectId]) -> Maybe ObjectId -> GameState.GameState -> Game a -> (GameState.GameState, Asked)
driving sprockets crank target gs game =
  let answering :: Prompt.Prompt r -> State.State ([Designation.Designation], Asked) r
      answering p = case p of
        Prompt.ChooseDesignation _ _ _ offered -> do
          (pending, asked) <- State.get
          let offeredList = foldr (:) [] offered
              recorded = asked {sprocketsOffered = sprocketsOffered asked <> [offeredList]}
          case pending of
            pick : rest -> State.put (rest, recorded) >> pure pick
            [] -> State.put ([], recorded) >> pure Designation.Sprocket3
        Prompt.ChooseAnyNumber _ _ _ AnyNumberOf.ToCrank offered _ -> do
          State.modify' (\(pending, asked) -> (pending, asked {cranksOffered = cranksOffered asked <> [offered]}))
          pure (Set.fromList (crank offered))
        -- FILTERED, NOT BUILT: the offered recipient that is `target`.
        Prompt.ChooseTargets _ _ _ slots -> pure (fmap (Set.filter ((== target) . Recipient.objectOf) . snd) slots)
        _ -> pure (S.identityAnswer p)
      ((_, after), (_, asked')) = State.runState (Engine.runGame answering gs game) (sprockets, MkAsked [] [])
   in (after, asked')

-- The Arms Depots on the battlefield, each with the sprockets it is on.
depotsOn :: GameState.GameState -> [Set.Set Designation.Designation]
depotsOn gs =
  [ Set.filter (`elem` [Designation.Sprocket1, Designation.Sprocket2, Designation.Sprocket3]) (Object.designations obj)
  | oid <- Set.toList (GameState.battlefield gs),
    Projection.namesOf oid gs == Set.singleton armsDepot,
    obj <- Maybe.maybeToList (Game.lookupObject oid gs)
  ]

plusCounters :: ObjectId -> GameState.GameState -> Integer
plusCounters oid gs = maybe 0 (toInteger . Map.findWithDefault 0 CounterKind.PlusOnePlusOne . Object.counters) (Game.lookupObject oid gs)

-- The Unstable FAQ's assemble, by a player.
assembleSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
assembleSpec s registry = Spec.describe s "Assemble" $ do
  Spec.it s "First Pick assembles Arms Depot onto the sprocket its caster chooses" $ do
    pick <- S.printingOf s registry "First Pick"
    depot <- S.printingOf s registry "Arms Depot"
    forest <- S.printingOf s registry "Forest"
    ornithopter <- S.printingOf s registry "Ornithopter"
    let (thopter, board) = S.addPermanent ornithopter S.bob (withDepots depot 2 S.alice (S.landsInPlay forest 4))
        (gs, spellId) = S.handOne pick board
        -- The second sprocket, which the prompt's default (its first) is not.
        (after, asked) = driving [Designation.Sprocket2] id (Just thopter) gs (S.cast S.alice spellId >> Engine.priorityLoop)
    -- THE GAMEPLAY ASSERTION: one Arms Depot is on the battlefield, on the
    -- sprocket alice chose.
    Spec.assertEqWith s "the Depot entered onto the second sprocket" (depotsOn after) [Set.singleton Designation.Sprocket2]
    Spec.assertEqWith s "under alice's control" (S.countOnBattlefieldByName armsDepot S.alice after) 1
    Spec.assertEqWith s "the three sprockets were offered, once" (sprocketsOffered asked) [[Designation.Sprocket1, Designation.Sprocket2, Designation.Sprocket3]]
    Spec.assertEqWith s "one card is left in the Contraption deck" (length (Game.sideDeckOf SideDeck.Contraption S.alice after)) 1
    Spec.assertBool s (not (Set.member thopter (GameState.battlefield after))) "and the Ornithopter was destroyed"
  Spec.it s "an empty Contraption deck assembles nothing and asks nothing" $ do
    pick <- S.printingOf s registry "First Pick"
    forest <- S.printingOf s registry "Forest"
    ornithopter <- S.printingOf s registry "Ornithopter"
    let (thopter, board) = S.addPermanent ornithopter S.bob (S.landsInPlay forest 4)
        (gs, spellId) = S.handOne pick board
        (after, asked) = driving [Designation.Sprocket2] id (Just thopter) gs (S.cast S.alice spellId >> Engine.priorityLoop)
    Spec.assertEqWith s "no Depot" (depotsOn after) []
    Spec.assertEqWith s "no sprocket asked" (sprocketsOffered asked) []
    Spec.assertBool s (not (Set.member thopter (GameState.battlefield after))) "though the rest of First Pick resolved"

-- alice controls an Arms Depot on `sprocket` and a Goblin Piker, and it is the
-- beginning of her upkeep. Answers the Depot and the Piker.
crankBoard :: Printing.Printing -> Printing.Printing -> Designation.Designation -> (GameState.GameState, ObjectId, ObjectId)
crankBoard depot piker sprocket =
  let (pikerId, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
      (depotId, g2) = S.addPermanent depot S.alice g1
      onSprocket = g2 {GameState.objects = Map.adjust (\o -> o {Object.designations = Set.insert sprocket (Object.designations o)}) depotId (GameState.objects g2)}
   in (onSprocket {GameState.phase = Phase.Beginning BeginningStep.Upkeep, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}, depotId, pikerId)

-- The upkeep's crank, then everything it triggered resolved.
upkeep :: Game ()
upkeep = Engine.runTurnBasedActions (Phase.Beginning BeginningStep.Upkeep) >> Engine.priorityLoop

-- The Gatherer rulings' crank at the beginning of the upkeep.
crankSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
crankSpec s registry = Spec.describe s "Crank" $ do
  Spec.it s "the CRANK! counter moves from the third sprocket to the first, cranking Arms Depot there" $ do
    depot <- S.printingOf s registry "Arms Depot"
    piker <- S.printingOf s registry "Goblin Piker"
    let (gs, depotId, pikerId) = crankBoard depot piker Designation.Sprocket1
        (after, asked) = driving [] id (Just pikerId) gs upkeep
    -- THE GAMEPLAY ASSERTION: the Depot's ability resolved onto the Piker.
    Spec.assertEqWith s "two +1/+1 counters on the Piker" (plusCounters pikerId after) 2
    Spec.assertEqWith s "the Depot was offered to crank" (cranksOffered asked) [[depotId]]
    Spec.assertEqWith s "the counter is on the first sprocket" (Contraption.crankCounterOf S.alice after) Designation.Sprocket1
  Spec.it s "a Contraption on another sprocket is not cranked" $ do
    depot <- S.printingOf s registry "Arms Depot"
    piker <- S.printingOf s registry "Goblin Piker"
    -- The board above, differing only in the Depot's sprocket.
    let (gs, _, pikerId) = crankBoard depot piker Designation.Sprocket2
        (after, asked) = driving [] id (Just pikerId) gs upkeep
    Spec.assertEqWith s "no counters on the Piker" (plusCounters pikerId after) 0
    Spec.assertEqWith s "nothing offered" (cranksOffered asked) []
    Spec.assertEqWith s "but the counter still moved" (Contraption.crankCounterOf S.alice after) Designation.Sprocket1
  Spec.it s "cranking is optional" $ do
    depot <- S.printingOf s registry "Arms Depot"
    piker <- S.printingOf s registry "Goblin Piker"
    let (gs, depotId, pikerId) = crankBoard depot piker Designation.Sprocket1
        (after, asked) = driving [] (const []) (Just pikerId) gs upkeep
    Spec.assertEqWith s "declined, so no counters" (plusCounters pikerId after) 0
    Spec.assertEqWith s "though the Depot was offered" (cranksOffered asked) [[depotId]]
  Spec.it s "a player who controls no Contraption keeps the counter where it is" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (_, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
        gs = g1 {GameState.phase = Phase.Beginning BeginningStep.Upkeep, GameState.activePlayer = S.alice, GameState.priority = Just S.alice}
        (after, _) = driving [] id Nothing gs upkeep
    Spec.assertEqWith s "still the third sprocket" (Contraption.crankCounterOf S.alice after) Designation.Sprocket3
  Spec.it s "the turn machinery itself cranks as the upkeep begins" $ do
    depot <- S.printingOf s registry "Arms Depot"
    piker <- S.printingOf s registry "Goblin Piker"
    let (gs, depotId, pikerId) = crankBoard depot piker Designation.Sprocket1
        (after, asked) = driving [] id (Just pikerId) gs Engine.runStep
    Spec.assertEqWith s "the Depot was offered to crank" (cranksOffered asked) [[depotId]]
    Spec.assertEqWith s "and its ability resolved in the upkeep" (plusCounters pikerId after) 2

-- Steamflogger Boss: its lord half and its replacement.
bossSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
bossSpec s registry = Spec.describe s "Steamflogger Boss" $ do
  Spec.it s "a Rigger alice controls assembles two Contraptions under the Boss, one without it" $ do
    boss <- S.printingOf s registry "Steamflogger Boss"
    rigger <- S.printingOf s registry "Wrench-Rigger"
    depot <- S.printingOf s registry "Arms Depot"
    mountain <- S.printingOf s registry "Mountain"
    let base = withDepots depot 3 S.alice (S.landsInPlay mountain 1)
        bossed = snd (S.addPermanent boss S.alice base)
        run board =
          let (gs, spellId) = S.handOne rigger board
           in driving [Designation.Sprocket2, Designation.Sprocket1] id Nothing gs (S.cast S.alice spellId >> Engine.priorityLoop)
        (withBoss, askedWith) = run bossed
        (without, askedWithout) = run base
    -- THE GAMEPLAY ASSERTION: two Depots under the Boss, each on its own
    -- sprocket as chosen; one without it.
    Spec.assertEqWith s "two Depots, on the sprockets chosen for each" (Set.fromList (depotsOn withBoss)) (Set.fromList [Set.singleton Designation.Sprocket2, Set.singleton Designation.Sprocket1])
    Spec.assertEqWith s "one Depot without the Boss" (depotsOn without) [Set.singleton Designation.Sprocket2]
    Spec.assertEqWith s "a sprocket asked for each" (fmap length (sprocketsOffered askedWith), fmap length (sprocketsOffered askedWithout)) ([3, 3], [3])
    Spec.assertEqWith s "one card left in the deck under the Boss" (length (Game.sideDeckOf SideDeck.Contraption S.alice withBoss)) 1
  Spec.it s "CR 608.2h a Rigger that left before its trigger resolved still assembles as a Rigger alice controlled" $ do
    boss <- S.printingOf s registry "Steamflogger Boss"
    rigger <- S.printingOf s registry "Wrench-Rigger"
    depot <- S.printingOf s registry "Arms Depot"
    mountain <- S.printingOf s registry "Mountain"
    let base = withDepots depot 3 S.alice (S.landsInPlay mountain 1)
        run board =
          let (gs, spellId) = S.handOne rigger board
              riggerGone = do
                S.cast S.alice spellId
                Monad.void Stack.resolveTop
                Monad.void Engine.placePendingTriggers
                g <- State.get
                Monad.forM_ (filter (\oid -> Projection.namesOf oid g == Set.singleton (CardName.MkCardName (Text.pack "Wrench-Rigger"))) (Set.toList (GameState.battlefield g))) $ \oid ->
                  Event.changeZone oid Zone.Graveyard
                Engine.priorityLoop
           in driving [Designation.Sprocket2, Designation.Sprocket1] id Nothing gs riggerGone
        (withBoss, _) = run (snd (S.addPermanent boss S.alice base))
        (without, _) = run base
    -- THE GAMEPLAY ASSERTION: the Boss reads the departed Rigger's last known
    -- information, so two Depots; without the Boss, one.
    Spec.assertEqWith s "two Depots under the Boss" (length (depotsOn withBoss)) 2
    Spec.assertEqWith s "one without it" (length (depotsOn without)) 1
    Spec.assertEqWith s "and the Rigger is in the graveyard" (length (Game.zoneMembers Zone.Graveyard S.alice withBoss)) 1
  Spec.it s "an opponent's Boss does not double alice's Rigger" $ do
    boss <- S.printingOf s registry "Steamflogger Boss"
    rigger <- S.printingOf s registry "Wrench-Rigger"
    depot <- S.printingOf s registry "Arms Depot"
    mountain <- S.printingOf s registry "Mountain"
    -- The first case's Boss board, differing only in who controls the Boss.
    let board = snd (S.addPermanent boss S.bob (withDepots depot 3 S.alice (S.landsInPlay mountain 1)))
        (gs, spellId) = S.handOne rigger board
        (after, _) = driving [Designation.Sprocket2, Designation.Sprocket1] id Nothing gs (S.cast S.alice spellId >> Engine.priorityLoop)
    Spec.assertEqWith s "alice's Rigger, out of reach of bob's Boss: one Depot" (depotsOn after) [Set.singleton Designation.Sprocket2]
  Spec.it s "the Boss does not double a player's assembly" $ do
    boss <- S.printingOf s registry "Steamflogger Boss"
    pick <- S.printingOf s registry "First Pick"
    depot <- S.printingOf s registry "Arms Depot"
    forest <- S.printingOf s registry "Forest"
    ornithopter <- S.printingOf s registry "Ornithopter"
    let (thopter, board) = S.addPermanent ornithopter S.bob (withDepots depot 3 S.alice (S.landsInPlay forest 4))
        bossed = snd (S.addPermanent boss S.alice board)
        (gs, spellId) = S.handOne pick bossed
        (after, _) = driving [] id (Just thopter) gs (S.cast S.alice spellId >> Engine.priorityLoop)
    Spec.assertEqWith s "First Pick's controller, not a Rigger, assembles: one Depot" (length (depotsOn after)) 1
  Spec.it s "other Riggers alice controls get +1/+0 and haste, and the Boss does not" $ do
    boss <- S.printingOf s registry "Steamflogger Boss"
    rigger <- S.printingOf s registry "Wrench-Rigger"
    let (riggerId, g1) = S.addPermanent rigger S.alice (Setup.emptyGame S.bothPlayers)
        (bossId, g2) = S.addPermanent boss S.alice g1
        (bobsRigger, gs) = S.addPermanent rigger S.bob g2
    Spec.assertEqWith s "the Wrench-Rigger is 2/1" (Projection.powerOf riggerId gs, Projection.toughnessOf riggerId gs) (Just 2, Just 1)
    Spec.assertBool s (Projection.hasKeyword Keyword.Haste riggerId gs) "and has haste"
    Spec.assertEqWith s "the Boss itself is 3/3" (Projection.powerOf bossId gs, Projection.toughnessOf bossId gs) (Just 3, Just 3)
    Spec.assertBool s (not (Projection.hasKeyword Keyword.Haste bossId gs)) "without haste"
    Spec.assertEqWith s "bob's Rigger is 1/1" (Projection.powerOf bobsRigger gs) (Just 1)

-- The Unstable FAQ's scrapyard.
scrapyardSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
scrapyardSpec s registry = Spec.describe s "Scrapyard" $ do
  Spec.it s "a Contraption leaving the battlefield for the graveyard goes to the scrapyard" $ do
    depot <- S.printingOf s registry "Arms Depot"
    let (depotId, gs) = S.addPermanent depot S.alice (Setup.emptyGame S.bothPlayers)
        binned = S.runPure S.identityAnswer gs (Event.changeZone depotId Zone.Graveyard)
        exiled = S.runPure S.identityAnswer gs (Event.changeZone depotId Zone.Exile)
    Spec.assertEqWith s "nothing in the graveyard" (Game.zoneMembers Zone.Graveyard S.alice binned) []
    Spec.assertEqWith s "one card in the command zone" (Set.size (GameState.command binned)) 1
    Spec.assertEqWith s "but exile is exile" (Set.size (GameState.exile exiled)) 1
  Spec.it s "a Contraption on no sprocket heads to the scrapyard as state is next checked" $ do
    depot <- S.printingOf s registry "Arms Depot"
    let (unassembledId, g1) = S.addPermanent depot S.alice (Setup.emptyGame S.bothPlayers)
        (assembledId, gs) = S.addPermanent depot S.alice g1
        onOne = gs {GameState.objects = Map.adjust (\o -> o {Object.designations = Set.insert Designation.Sprocket1 (Object.designations o)}) assembledId (GameState.objects gs)}
        checked = S.runPure S.identityAnswer onOne (Sba.checkStateBasedActions S.insteadOfLoss)
    Spec.assertBool s (not (Set.member unassembledId (GameState.battlefield checked))) "the Depot on no sprocket left the battlefield"
    Spec.assertEqWith s "for the scrapyard" (Set.size (GameState.command checked)) 1
    Spec.assertBool s (Set.member assembledId (GameState.battlefield checked)) "and the one on a sprocket stayed"
  Spec.it s "a copy of a Contraption was not assembled, and its card goes to the graveyard" $ do
    depot <- S.printingOf s registry "Arms Depot"
    metamorph <- S.printingOf s registry "Phyrexian Metamorph"
    let (original, board) = S.addPermanent depot S.alice (Setup.emptyGame S.bothPlayers)
        assembled = board {GameState.objects = Map.adjust (\o -> o {Object.designations = Set.insert Designation.Sprocket1 (Object.designations o)}) original (GameState.objects board)}
        copyAnswer :: Prompt.Prompt r -> r
        copyAnswer p = case p of
          Prompt.ChooseCopyTarget {} -> Just original
          _ -> S.identityAnswer p
        (_, staged) = S.spellOnStack metamorph S.alice assembled
        entered = S.runPure copyAnswer staged (Stack.resolveTop >> Sba.checkStateBasedActions S.insteadOfLoss)
    Spec.assertEqWith s "the Metamorph card is in alice's graveyard" (length (Game.zoneMembers Zone.Graveyard S.alice entered)) 1
    Spec.assertEqWith s "nothing went to the scrapyard" (GameState.command entered) Set.empty
    Spec.assertBool s (Set.member original (GameState.battlefield entered)) "and the assembled Depot stayed"

-- The Contraption deck across CR 727's restart and CR 729's subgames, read as
-- CR 727.2 and CR 729.2a / 729.5a read the Attraction deck.
newGameSpec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
newGameSpec s registry = Spec.describe s "A new game" $ do
  Spec.it s "CR 727.2 a restart puts every Contraption card back in its owner's Contraption deck" $ do
    depot <- S.printingOf s registry "Arms Depot"
    piker <- S.printingOf s registry "Goblin Piker"
    let (gs, _, pikerId) = crankBoard depot piker Designation.Sprocket1
        -- One upkeep first, so the counter has left the third sprocket.
        (cranked, _) = driving [] id (Just pikerId) gs upkeep
        board = withDepots depot 1 S.alice cranked
        restarted = S.runPure S.identityAnswer board (Setup.restartGame (Resolve.performHandAction Resolve.noSubgame) Set.empty S.alice)
    Spec.assertEqWith s "the counter had moved to the first sprocket" (Contraption.crankCounterOf S.alice board) Designation.Sprocket1
    Spec.assertEqWith s "both Depots are in alice's Contraption deck" (length (Game.sideDeckOf SideDeck.Contraption S.alice restarted)) 2
    Spec.assertEqWith s "and neither is on the battlefield" (S.countOnBattlefieldByName armsDepot S.alice restarted) 0
    Spec.assertEqWith s "the CRANK! counter is back on the third sprocket" (Contraption.crankCounterOf S.alice restarted) Designation.Sprocket3
  Spec.it s "CR 729.2a a subgame takes the Contraption deck, and CR 729.5a gives it back" $ do
    depot <- S.printingOf s registry "Arms Depot"
    piker <- S.printingOf s registry "Goblin Piker"
    let (gs, assembled, pikerId) = crankBoard depot piker Designation.Sprocket1
        (cranked, _) = driving [] id (Just pikerId) gs upkeep
        parent = withDepots depot 1 S.alice cranked
        sub = S.runPure S.identityAnswer (Setup.subgameStateFrom S.alice parent) (Setup.startGameFromCards (Resolve.performHandAction Resolve.noSubgame) Set.empty)
        back = Setup.funnelBack sub parent
    Spec.assertEqWith s "CR 729.2a: the deck is in the subgame" (length (Game.sideDeckOf SideDeck.Contraption S.alice sub)) 1
    Spec.assertBool s (Maybe.isNothing (Game.lookupObject assembled sub)) "and the assembled one stayed behind"
    Spec.assertEqWith s "CR 729.5a: the deck is back" (length (Game.sideDeckOf SideDeck.Contraption S.alice back)) 1
    Spec.assertEqWith s "and the assembled one never moved" (Game.zoneOf assembled back) (Just Zone.Battlefield)
    Spec.assertEqWith s "the subgame's CRANK! counter starts on the third sprocket" (Contraption.crankCounterOf S.alice sub) Designation.Sprocket3
    Spec.assertEqWith s "and the main game's is where it was" (Contraption.crankCounterOf S.alice back) Designation.Sprocket1
