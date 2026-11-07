{-# LANGUAGE GADTs #-}

-- Covers Parun.Play.Client, Parun.Play.Render and Parun.Play.Game: a person at
-- a terminal playing through request lines, against the bot or another
-- person on the same screen.
module Parun.ClientSpec where

import qualified Control.Exception as Exception
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Char as Char
import qualified Data.Either as Either
import qualified Data.Foldable as Foldable
import qualified Data.Functor.Identity as Identity
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Word as Word
import Numeric.Natural (Natural)
import qualified Parun.BotSpec as BotSpec
import qualified Parun.CastProhibitionSpec as CastProhibitionSpec
import qualified Parun.Engine.Binding as Binding
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Game as Game.Engine
import qualified Parun.Engine.Mana as Mana
import qualified Parun.Engine.PlayerView as PlayerView
import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Engine.Stack as Stack
import qualified Parun.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Parun.Extra.Natural as Natural
import qualified Parun.ManaSpec as ManaSpec
import qualified Parun.Play.Bot as Bot
import qualified Parun.Play.Client as Client
import qualified Parun.Play.Game as Game
import qualified Parun.Play.Render as Render
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Acquisition as Acquisition
import qualified Parun.Types.Action as Action
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.AnyNumberOf as AnyNumberOf
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.BecameAttached as BecameAttached
import qualified Parun.Types.BecameUnattached as BecameUnattached
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Combat as Combat.Type
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Convoking as Convoking
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CountersPlaced as CountersPlaced
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.Dividing as Dividing
import qualified Parun.Types.Drew as Drew
import qualified Parun.Types.EventGroup as EventGroup
import qualified Parun.Types.Face as Face
import qualified Parun.Types.FaceDownReason as FaceDownReason
import qualified Parun.Types.Facing as Facing
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GraveyardArrangement as GraveyardArrangement
import qualified Parun.Types.Hotseat as Hotseat
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.HybridPayment as HybridPayment
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ManaUnit as ManaUnit
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.Moved as Moved
import qualified Parun.Types.MulliganDecision as MulliganDecision
import qualified Parun.Types.MulliganOffer as MulliganOffer
import qualified Parun.Types.NumberFloor as NumberFloor
import qualified Parun.Types.Object as Object
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.OptionalDecision as OptionalDecision
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayOptions as PlayOptions
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerView as PlayerView.Type
import qualified Parun.Types.ProductionTag as ProductionTag
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Result as Result
import qualified Parun.Types.RevealCause as RevealCause
import qualified Parun.Types.Revealed as Revealed
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SplitMix as SplitMix
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.Terminal as Terminal
import qualified Parun.Types.TriggerEntry as TriggerEntry
import qualified Parun.Types.TriggerSource as TriggerSource
import qualified Parun.Types.Undoing as Undoing
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange
import qualified Text.Read as Read

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Client" $ do
  Spec.it s "a person who plays lands and casts spells finishes a game against the bot" $ do
    matchup <- BotSpec.bears s registry
    let (outcome, shown) = against plays matchup
    Spec.assertBool s (either (const False) (const True) outcome) ("finished: " <> show (fmap fst outcome))
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Your hand: ")) shown) "hand"
    Spec.assertBool s (any (\l -> Text.isPrefixOf (Text.pack "  Creatures: ") l && Text.isInfixOf (Text.pack "Grizzly Bears 2/2") l) shown) "cast"

  Spec.it s "a seat that types concede loses at its next priority" $ do
    matchup <- BotSpec.bears s registry
    let conceding sc = if not (typedYet "concede" sc) && any menuHeading (pending sc) then Just (Text.pack "concede") else plays sc
    Spec.assertEq s (fmap fst (fst (against conceding matchup))) (Right (Result.Won S.bob))

  Spec.it s "an option that is not offered is asked again before reaching the engine" $ do
    matchup <- BotSpec.bears s registry
    let straying sc = if not (typedYet "99" sc) && any menuHeading (pending sc) then Just (Text.pack "99") else plays sc
        shown = snd (against straying matchup)
        after = drop 1 (dropWhile (/= Text.pack "> 99") shown)
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Type one number from 1 to")) (take 1 after)) "asked again"
    Spec.assertBool s (any menuHeading after) "played on"

  Spec.it s "a change of seat waits for the seat leaving to finish reading, clears the screen, and waits before showing the next seat" $ do
    matchup <- BotSpec.bears s registry
    let people = Map.fromList [(S.alice, Game.human (screen 300 plays) (const (Right Nothing))), (S.bob, Game.human (screen 300 plays) (const (Right Nothing)))]
        shown = reverse (written (State.execState (Game.run (S.fixtureRegistry []) [] people (const (pure ())) Hotseat.fresh (SplitMix.MkSplitMix 1) Map.empty matchup) blank))
        handOffs = [i | (i, l) <- zip [0 :: Int ..] shown, Text.isPrefixOf (Text.pack "Pass to ") l]
        at i = Maybe.listToMaybe (drop i shown)
        -- The last hand-off may be cut short by the end of input.
        cleared i = at (i - 1) == Just (Text.pack "<clear>") && (at (i + 2) == Just (Text.pack "<clear>") || at (i + 1) == Just (Text.pack "<eof>"))
        -- Nothing said since the seat leaving last typed a line, or the first
        -- hand-off, with no seat yet looking.
        readFirst i = i < 2 || maybe False (Text.isPrefixOf (Text.pack "> ")) (at (i - 2))
    Spec.assertBool s (all readFirst handOffs) ("read before the clear: " <> show [take 3 (drop (i - 3) shown) | i <- handOffs, not (readFirst i)])
    Spec.assertBool s (Text.pack "Press Enter to pass the screen on." `elem` shown) "asked to finish reading"
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Pass to Player 1")) shown && any (Text.isPrefixOf (Text.pack "Pass to Player 2")) shown) "both seats"
    Spec.assertBool s (all cleared handOffs) "cleared"
    Spec.assertEqWith s "seen by the seat passed to" (mismatches shown) []

  Spec.it s "a seat is shown what it witnessed once" $ do
    gs <- started s registry
    let revealed = GameEvent.Revealed (Revealed.MkRevealed S.bob (ObjectId.MkObjectId 7) RevealCause.LeavingFaceDown S.emptyCharacteristics)
        witnessing = gs {GameState.events = Seq.singleton (LoggedEvent.MkLoggedEvent (EventGroup.MkEventGroup 0) revealed)}
        acting = Asked.MkAsked [] witnessing (Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass])
        twice = Answerer.unwrap human acting >> Answerer.unwrap human acting
        human = Game.human (screen 2 (const (Just (Text.pack "1")))) (const (Right Nothing))
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT twice (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.autoPass = False})) blank))
    Spec.assertEqWith s "once" (filter (Text.isInfixOf (Text.pack "reveals")) shown) [Text.pack "Player 2 reveals a face-down card."]

  Spec.it s "a seat passed for while facing the screen is shown its creature spell resolving" $ do
    gs <- started s registry
    lands <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Forest"]
    bears <- S.printingOf s registry "Grizzly Bears"
    let (board, _) = S.handOne bears (List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs lands)
        turn = GameState.turnNumber board
        seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 (castsOnce "auto" "Grizzly Bears")) (const (Right Nothing)))) botOrDefault
        run = Driver.drive [] seats 40 (pure . (> turn) . GameState.turnNumber) board
        (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank
        -- Since alice last answered: the auto payment ends her questions.
        unanswered = pending sc
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Grizzly Bears moves from the stack to the battlefield")) unanswered) ("shown the bear resolve: " <> show unanswered)
    Spec.assertEqWith s "as a line of its own, to a seat that never stopped looking" (filter (Text.isPrefixOf (Text.pack "Since you last looked")) unanswered) []
    Spec.assertBool s (Text.pack "Player 1 passes in their precombat main phase (no other actions)." `elem` unanswered) "passed for, in its main phase"
    Spec.assertEqWith s "into the next turn" (fmap ((> turn) . GameState.turnNumber) outcome) (Right True)

  Spec.it s "a seat the screen does not face is handed it at a priority offering only passing, and shown its news there" $ do
    gs <- started s registry
    hand <- maybe (Spec.assertFailure s "no card in hand") pure (Maybe.listToMaybe (Game.Engine.zoneMembers Zone.Hand S.alice gs))
    let revealed = GameEvent.Revealed (Revealed.MkRevealed S.bob (ObjectId.MkObjectId 7) RevealCause.LeavingFaceDown S.emptyCharacteristics)
        decider = Decider.MkDecider S.alice
        witnessing = gs {GameState.events = Seq.fromList (fmap (LoggedEvent.MkLoggedEvent (EventGroup.MkEventGroup 0)) [revealed, revealed])}
        nextTurn = gs {GameState.events = Seq.empty, GameState.turnNumber = GameState.turnNumber gs + 1}
        passing = Answerer.unwrap human (Asked.MkAsked [] witnessing (Prompt.ChooseAction decider S.alice [Action.Pass]))
        acting = Answerer.unwrap human (Asked.MkAsked [] nextTurn (Prompt.ChooseAction decider S.alice [Action.Play hand Nothing, Action.Pass]))
        -- Enter at the hand-off and to pass, then Pass.
        human = Game.human (screen 3 (\sc -> Just (Text.pack (if typed sc < 2 then "" else "2")))) (const (Right Nothing))
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT (passing >> acting) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Just S.bob})) blank))
        (facingBob, facingAlice) = break (Text.isPrefixOf (Text.pack "Pass to Player 1")) shown
        news = filter (Text.isPrefixOf (Text.pack "Since you last looked: "))
    Spec.assertEqWith s "nothing said while the screen faces Player 2" facingBob [Text.pack "<clear>"]
    Spec.assertEqWith s "shown once, at the hand-off, sentence after sentence" (news facingAlice) [Text.pack "Since you last looked: Player 2 reveals a face-down card. Player 2 reveals a face-down card."]
    Spec.assertEqWith s "asked twice" (filter menuHeading facingAlice) [Text.pack "Choose an action, or press Enter to pass:", Text.pack "Choose an action, or press Enter to pass:"]

  Spec.it s "CR 514.1 a discard to hand size at cleanup is shown the other seat at its next question, a turn later" $ do
    gs <- started s registry
    giant <- S.printingOf s registry "Hill Giant"
    let board = snd (S.addHandCard giant S.alice gs)
        turn = GameState.turnNumber board
        person = Game.human (screen 200 discardsGiant) (const (Right Nothing))
        seats = Driver.bySeat (Map.fromList [(S.alice, person), (S.bob, person)]) botOrDefault
        run = Driver.drive [] seats 200 (pure . (> turn + 1) . GameState.turnNumber) board
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank))
        discarding = Text.isPrefixOf (Text.pack "Choose 1 card to discard")
        -- Bob's first screen after the discard.
        facingBob = takeWhile (not . Text.isPrefixOf (Text.pack "Pass to Player 1")) (dropWhile (not . Text.isPrefixOf (Text.pack "Pass to Player 2")) (dropWhile (not . discarding) shown))
        news = filter (Text.isPrefixOf (Text.pack "Since you last looked: ")) facingBob
    Spec.assertBool s (any (Text.isInfixOf (Text.pack "Player 1 discards Hill Giant.")) news) ("shown the discard: " <> show news)
    Spec.assertBool s (not (any (Text.isInfixOf (Text.pack "Hill Giant is put into a graveyard")) news)) ("the discard's move, told once: " <> show news)
    Spec.assertBool s (any discarding shown) "Player 1 discarded at cleanup"

  Spec.it s "CR 730.1a a seat back from a Shahrazad subgame played past the main game's turn is shown the main game's news it was not yet shown" $ do
    plains <- S.printingOf s registry "Plains"
    mountain <- S.printingOf s registry "Mountain"
    shahrazad <- S.printingOf s registry "Shahrazad"
    -- Eight library cards each once Player 1 draws: the subgame's turn 4 draw
    -- decks its second seat (CR 704.5b), past the main game's turn 3.
    let stock pid n g = List.foldl' (\g' _ -> snd (S.addLibraryCard mountain pid g')) g (replicate n ())
        board = (snd (S.addHandCard shahrazad S.alice (S.landsFor plains S.alice 2 (stock S.bob 8 (stock S.alice 9 (Setup.emptyGame (S.alice NonEmpty.:| [S.bob]))))))) {GameState.turnNumber = 3}
        person = Game.human (screen 400 (castsOnce "auto" "Shahrazad")) (const (Right Nothing))
        seats = Driver.bySeat (Map.fromList [(S.alice, person), (S.bob, person)]) botOrDefault
        run = Driver.drive [] seats 40 (pure . (> 3) . GameState.turnNumber) board
        (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank
        shown = reverse (written sc)
        -- Player 1's last look at the subgame, in its turn 4, then its first
        -- screen in the resumed main game, up to the hand.
        lastLook = Text.pack "Turn 4, Player 2's upkeep. Priority: Player 1."
        since = reverse (takeWhile (/= lastLook) (reverse shown))
        resumed = takeWhile (not . Text.isPrefixOf (Text.pack "Your hand")) (drop 1 (dropWhile (not . Text.isPrefixOf (Text.pack "> ")) since))
        summary line = any (`Text.isPrefixOf` line) [Text.pack "Turn ", Text.pack "Player 1 (you)", Text.pack "Player 2: ", Text.pack "  "] || Text.null line
    Spec.assertBool s (elem lastLook shown) "the subgame reached its turn 4"
    Spec.assertEqWith s "exactly the main game's entries not yet shown, once" (filter (not . summary) resumed) [Text.pack "Player 2 loses 10 life.", Text.pack "Shahrazad is put into a graveyard from the stack."]
    Spec.assertEqWith s "into the main game's next turn" (fmap GameState.turnNumber outcome) (Right 4)

  Spec.it s "CR 113.7a Mindslaver's ability is named by its source at its target prompt and on the stack" $ do
    gs <- started s registry
    mindslaver <- S.printingOf s registry "Mindslaver"
    mountains <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Mountain", "Mountain"]
    let board = List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs (mindslaver : mountains)
        turn = GameState.turnNumber board
        seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 slavesBob) (const (Right Nothing)))) botOrDefault
        run = Driver.drive [] seats 200 (pure . (> turn) . GameState.turnNumber) board
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.autoPass = False})) blank))
        stacks = filter (Text.isPrefixOf (Text.pack "Stack, top first: "))
        stackLine = Text.pack "Stack, top first: Mindslaver's ability"
    -- Asked while Mindslaver is on the battlefield; the stack shown then and
    -- once its sacrifice has moved it, a witnessed move naming it.
    Spec.assertBool s (Text.pack "Choose 1 target for Mindslaver's ability:" `elem` shown) "the target prompt names it"
    Spec.assertEqWith s "CR 601.2h its cost's components, numbered" (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (not . Text.isPrefixOf (Text.pack "Order cost components for Mindslaver:")) shown))) [Text.pack "  1. {T}", Text.pack "  2. Sacrifice Mindslaver"]
    Spec.assertEqWith s "the stack names it, then once it is sacrificed" (Set.toList (Set.fromList (stacks shown)), take 1 (stacks (dropWhile (/= Text.pack "  Graveyard: Mindslaver") shown))) ([stackLine], [stackLine])
    Spec.assertEqWith s "no face-down card" (filter (Text.isInfixOf (Text.pack "face-down")) shown) []
    Spec.assertEqWith s "CR 602.2 the activation names its player and source" (filter (Text.isInfixOf (Text.pack "activate")) shown) [Text.pack "Player 1 activates Mindslaver's ability."]

  Spec.it s "CR 608.2d each hotseat bidder at Illicit Auction is shown the high bid as the least it may bid, which lets it stand" $ do
    gs <- started s registry
    auction <- S.printingOf s registry "Illicit Auction"
    giant <- S.printingOf s registry "Hill Giant"
    mountains <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Mountain", "Mountain", "Mountain"]
    let (giantId, withGiant) = S.addPermanent giant S.bob gs
        board = snd (S.addHandCard auction S.alice (List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) withGiant mountains))
        person = Game.human (screen 400 bids) (const (Right Nothing))
        seats = Driver.bySeat (Map.fromList [(S.alice, person), (S.bob, person)]) botOrDefault
        run = Driver.drive [] seats 400 (pure . (== Just S.alice) . Projection.controllerOf giantId) board
        (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank
        shown = reverse (written sc)
        heading = Text.isPrefixOf (Text.pack "Choose a number for Illicit Auction")
    -- Player 2 tops 0 with 3; Player 1 is refused 2, asked again, and tops
    -- with 4, which Player 2 lets stand.
    Spec.assertEqWith s "each bid prompt, and the refusal" (filter (\line -> heading line || Text.isPrefixOf (Text.pack "Type a number") line) shown) (fmap Text.pack ["Choose a number for Illicit Auction, at least 0; 0 lets the high bid stand:", "Choose a number for Illicit Auction, at least 3; 3 lets the high bid stand:", "Type a number of at least 3.", "Choose a number for Illicit Auction, at least 3; 3 lets the high bid stand:", "Choose a number for Illicit Auction, at least 4; 4 lets the high bid stand:"])
    Spec.assertEqWith s "Player 1 wins the Hill Giant for 4 life" (fmap (S.lifeOf S.alice) outcome) (Right (Just 16))

  Spec.it s "CR 724.6 a seat controlled for its turn is still shown the rest of the turn before, and that turn, at its next question" $ do
    gs <- started s registry
    giant <- S.printingOf s registry "Hill Giant"
    mindslaver <- S.printingOf s registry "Mindslaver"
    mountains <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Mountain", "Mountain"]
    let board = snd (S.addHandCard giant S.alice (List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs (mindslaver : mountains)))
        turn = GameState.turnNumber board
        person = Game.human (screen 400 slavesBob) (const (Right Nothing))
        seats = Driver.bySeat (Map.fromList [(S.alice, person), (S.bob, person)]) botOrDefault
        run = Driver.drive [] seats 400 (pure . (> turn + 3) . GameState.turnNumber) board
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank))
        facingBob = facedBy (Text.pack "Pass to Player 2") shown
        news = filter (Text.isPrefixOf (Text.pack "Since you last looked: ")) facingBob
    Spec.assertBool s (any (Text.isInfixOf (Text.pack "Player 1 discards Hill Giant.")) news) ("shown the turn before's discard: " <> show news)
    Spec.assertBool s (any (Text.isInfixOf (Text.pack "Player 2 discards ")) news) ("shown its own turn's discard: " <> show news)
    -- One discard each turn; Player 2 answered only its turn 4's, Player 1
    -- the rest, its turn 2's included.
    let discards = length . filter (Text.isPrefixOf (Text.pack "Choose 1 card to discard"))
    Spec.assertEqWith s "discards, and those Player 2 answered" (discards shown, discards facingBob) (4, 1)

  Spec.it s "each reader's answer reads as its prompt's answer" $ do
    gs <- started s registry
    let o5 = ObjectId.MkObjectId 5
        o7 = ObjectId.MkObjectId 7
        o9 = ObjectId.MkObjectId 9
        slot = SlotName.MkSlotName (Text.pack "target")
        alice = Decider.MkDecider S.alice
        bob = Decider.MkDecider S.bob
    Spec.assertEqWith s "attackers" (answering gs "2" (Prompt.DeclareAttackers alice S.alice [o7, o9])) (Right [o9])
    -- On a real combat: the line refuses a block the rules forbid.
    giant <- S.printingOf s registry "Hill Giant"
    case S.combatBoardOf [giant] [giant, giant] of
      (board, [attacker], [first, second]) -> do
        let blocking = board {GameState.phase = Phase.Combat CombatStep.DeclareBlockers, GameState.combat = (GameState.combat board) {Combat.Type.attackers = Map.singleton attacker (AttackTarget.OfPlayer S.bob)}}
        Spec.assertEqWith s "blockers" (answering blocking "2:1" (Prompt.DeclareBlockers bob S.bob [first, second] [attacker])) (Right (Map.singleton second (Set.singleton attacker)))
      _ -> Spec.assertFailure s "fixture should have one attacker and two blockers"
    -- Player 2 first: the view shows no seat for o9, so it is listed last.
    Spec.assertEqWith s "targets" (answering gs "2" (Prompt.ChooseTargets alice S.alice o7 (Map.singleton slot (1, Set.fromList [Recipient.ToPlayer S.bob, Recipient.ToCreature o9])))) (Right (Map.singleton slot (Set.singleton (Recipient.ToCreature o9))))
    Spec.assertEqWith s "optional" (answering gs "2" (Prompt.ChooseOptional alice S.alice o7 (ModeIndex.MkModeIndex 0) (ClauseIndex.MkClauseIndex 0) mempty)) (Right OptionalDecision.Declines)
    Spec.assertEqWith s "life for mana" (answering gs "1" (Prompt.PayLifeForMana alice S.alice 1 ManaType.Colorless)) (Right OptionalDecision.Exercises)
    Spec.assertEqWith s "x" (answering gs "3" (Prompt.ChooseX alice S.alice o7 Binding.variableX 1 5)) (Right 3)
    Spec.assertEqWith s "number" (answering gs "2" (Prompt.ChooseNumber alice S.alice o7 1 NumberFloor.Least (Just 2))) (Right 2)
    let (_, pastBound) = asking Hotseat.fresh {Hotseat.facing = Just S.alice} ["3"] gs (Prompt.ChooseNumber alice S.alice o7 1 NumberFloor.Least (Just 2))
    Spec.assertEqWith s "a number past its bound is refused by its range" (filter (Text.isPrefixOf (Text.pack "Type a number")) pastBound) [Text.pack "Type a number from 1 to 2."]
    Spec.assertEqWith s "a number that is no bid notes no high bid, asked again once refused" (filter (Text.isPrefixOf (Text.pack "Choose a number")) pastBound) (replicate 2 (Text.pack "Choose a number for object 7, from 1 to 2:"))
    Spec.assertEqWith s "an unbounded number" (answering gs "99" (Prompt.ChooseNumber alice S.alice o7 3 NumberFloor.Least Nothing)) (Right 99)
    Spec.assertEqWith s "combat damage" (answering gs "1 2" (Prompt.AssignCombatDamage alice S.alice o7 (Map.fromList [(Recipient.ToCreature o5, 0), (Recipient.ToCreature o9, 0)]) 3)) (Right (Map.fromList [(Recipient.ToCreature o5, 1), (Recipient.ToCreature o9, 2)]))
    Spec.assertEqWith s "division" (answering gs "3 1" (Prompt.ChooseDivision alice S.alice o7 (Dividing.Total 4) (Recipient.ToCreature o9 NonEmpty.:| [Recipient.ToPlayer S.bob]))) (Right (Map.fromList [(Recipient.ToCreature o9, 3), (Recipient.ToPlayer S.bob, 1)]))
    Spec.assertEqWith s "fixed parts" (answering gs "1 3" (Prompt.ChooseDivision alice S.alice o7 (Dividing.Parts (1 NonEmpty.:| [3])) (Recipient.ToCreature o9 NonEmpty.:| [Recipient.ToCreature o5]))) (Right (Map.fromList [(Recipient.ToCreature o9, 1), (Recipient.ToCreature o5, 3)]))
    Spec.assertEqWith s "mana source" (answering gs "stop" (Prompt.ChooseManaSource alice S.alice (ManaCost.MkManaCost [ManaSymbol.Generic 1]) (o7 NonEmpty.:| [o9]))) (Right Nothing)

  Spec.it s "Enter passes at a priority offering Pass, and the menu says so" $ do
    (forest, gs) <- withForest s registry
    hand <- maybe (Spec.assertFailure s "no card in hand") pure (Maybe.listToMaybe (Game.Engine.zoneMembers Zone.Hand S.alice gs))
    let decider = Decider.MkDecider S.alice
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        (passed, shown) = asking facing [""] gs (Prompt.ChooseAction decider S.alice [Action.Play hand Nothing, Action.ActivateManaAbility forest, Action.Pass])
        (unpassable, unpassableShown) = asking facing [""] gs (Prompt.ChooseAction decider S.alice [Action.Play hand Nothing, Action.ActivateManaAbility forest])
    Spec.assertEqWith s "passed" passed (Right Action.Pass)
    Spec.assertBool s (Text.pack "Choose an action, or press Enter to pass:" `elem` shown) "the menu names Enter"
    Spec.assertEqWith s "refused with no Pass to pick" unpassable (Left (Text.pack "end of input"))
    Spec.assertBool s (Text.pack "Choose an action:" `elem` unpassableShown) "the menu names no Enter"

  Spec.it s "a mana source takes stop and auto as words, and Enter as auto; a covered cost takes Enter to pay now" $ do
    gs <- started s registry
    taiga <- S.printingOf s registry "Taiga"
    plateau <- S.printingOf s registry "Plateau"
    let (t, g1) = S.addPermanent taiga S.alice gs
        (p, board) = S.addPermanent plateau S.alice g1
        decider = Decider.MkDecider S.alice
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        cost = ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.Red), ManaSymbol.OfType (ManaType.Colored Color.Green)]
        paying = Prompt.ChooseManaSource decider S.alice cost (t NonEmpty.:| [p])
        covered = Prompt.ChooseExtraManaSource decider S.alice (t NonEmpty.:| [p])
        (entered, shown) = asking facing [""] board paying
        (coveredEntered, coveredShown) = asking facing [""] board covered
    Spec.assertEqWith s "Enter pays with auto's Plateau" entered (Right (Just p))
    Spec.assertBool s (Text.pack "Paying {R}{G}. Choose a source to pay with, stop to stop paying, or auto (or press Enter) to pay the rest:" `elem` shown) "the words and Enter listed"
    Spec.assertEqWith s "stop stops" (fst (asking facing ["stop"] board paying)) (Right Nothing)
    Spec.assertEqWith s "0 is no longer a word" (fst (asking facing ["0"] board paying)) (Left (Text.pack "end of input"))
    Spec.assertEqWith s "Enter pays now" coveredEntered (Right Nothing)
    Spec.assertBool s (Text.pack "The cost is covered. Choose another source to activate, or press Enter to pay now:" `elem` coveredShown) "Enter listed"
    Spec.assertEqWith s "0 is no longer pay now" (fst (asking facing ["0"] board covered)) (Left (Text.pack "end of input"))

  Spec.it s "all and a range pick options, and a count-bound pick takes them only at its count" $ do
    gs <- started s registry
    let o5 = ObjectId.MkObjectId 5
        o7 = ObjectId.MkObjectId 7
        o9 = ObjectId.MkObjectId 9
        alice = Decider.MkDecider S.alice
        attacking = Prompt.DeclareAttackers alice S.alice [o5, o7, o9]
        discarding = Prompt.ChooseDiscard alice S.alice [o5, o7, o9] 2
    Spec.assertEqWith s "all attack" (answering gs "all" attacking) (Right [o5, o7, o9])
    Spec.assertEqWith s "a range attacks" (answering gs "2-3" attacking) (Right [o7, o9])
    Spec.assertEqWith s "a backward range is refused, not read as none" (answering gs "3-2" attacking) (Left (Text.pack "end of input"))
    Spec.assertEqWith s "a range of the count discards" (answering gs "1-2" discarding) (Right [o5, o7])
    Spec.assertEqWith s "all of three is refused for two" (answering gs "all" discarding) (Left (Text.pack "end of input"))

  Spec.it s "a run of one player's draws is told as one" $ do
    gs <- started s registry
    let drew pid n = LoggedEvent.MkLoggedEvent (EventGroup.MkEventGroup n) (GameEvent.Drew (Drew.MkDrew pid n))
        drawing = gs {GameState.events = Seq.fromList [drew S.bob 1, drew S.bob 2, drew S.alice 1, drew S.bob 3]}
        shown = snd (asking Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.autoPass = False} [] drawing (Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass]))
    Spec.assertEqWith s "told" (filter (Text.isInfixOf (Text.pack " draws ")) shown) [Text.pack "Player 2 draws 2 cards.", Text.pack "Player 1 draws a card.", Text.pack "Player 2 draws a card."]

  Spec.it s "options for cards in hand the view shows alike merge, and a card shown otherwise under the same name stays apart" $ do
    forest <- S.printingOf s registry "Forest"
    let (a, g1) = S.addHandCard forest S.alice (Setup.emptyGame S.bothPlayers)
        (b, g2) = S.addHandCard forest S.alice g1
        (c, g3) = S.addHandCard forest S.alice g2
        gs = g3 {GameState.objects = Map.adjust (\o -> o {Object.counters = Map.singleton CounterKind.PlusOnePlusOne 1}) c (GameState.objects g3)}
        playing = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Play a Nothing, Action.Play b Nothing, Action.Play c Nothing, Action.Pass]
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        (second, shown) = asking facing ["2"] gs playing
    Spec.assertEqWith s "the menu" (actionMenus shown) [[Text.pack "Play Forest", Text.pack "Play Forest", Text.pack "Pass"]]
    Spec.assertEqWith s "the second is the Forest with a counter" second (Right (Action.Play c Nothing))
    Spec.assertEqWith s "the first is the first alike" (fst (asking facing ["1"] gs playing)) (Right (Action.Play a Nothing))
    Spec.assertEqWith s "the third passes" (fst (asking facing ["3"] gs playing)) (Right Action.Pass)

  Spec.it s "a priority offering only passing and mana abilities is passed without asking for the seat the screen faces" $ do
    (forest, gs) <- withForest s registry
    hand <- maybe (Spec.assertFailure s "no card in hand") pure (Maybe.listToMaybe (Game.Engine.zoneMembers Zone.Hand S.alice gs))
    let decider = Decider.MkDecider S.alice
        manaOnly = Prompt.ChooseAction decider S.alice [Action.ActivateManaAbility forest, Action.Pass]
        facingBob = Hotseat.fresh {Hotseat.facing = Just S.bob}
        facingAlice = Hotseat.fresh {Hotseat.facing = Just S.alice}
        upkeep = gs {GameState.phase = Phase.Beginning BeginningStep.Upkeep, GameState.activePlayer = S.bob}
    Spec.assertEqWith s "passed for, in the other seat's upkeep" (asking facingAlice [] upkeep manaOnly) (Right Action.Pass, [Text.pack "Player 1 draws 7 cards.", Text.pack "Player 2 draws 7 cards.", Text.pack "Player 1 keeps.", Text.pack "Player 2 keeps.", Text.pack "Player 1 passes in Player 2's upkeep (no other actions)."])
    let menu (outcome, shown) = (outcome, any menuHeading shown)
        handedOff (outcome, shown) = (outcome, take 2 shown)
    Spec.assertEqWith s "handed off and asked, facing another seat" (handedOff (asking facingBob ["", ""] upkeep manaOnly)) (Right Action.Pass, [Text.pack "<clear>", Text.pack "Pass to Player 1, then press Enter."])
    Spec.assertEqWith s "asked when turned off" (menu (asking facingAlice {Hotseat.autoPass = False} [] gs manaOnly)) (Left (Text.pack "end of input"), True)
    Spec.assertEqWith s "asked with a land to play" (menu (asking facingAlice [] gs (Prompt.ChooseAction decider S.alice [Action.Play hand Nothing, Action.Pass]))) (Left (Text.pack "end of input"), True)

  Spec.it s "a person against the bot is never shown an action menu of passing and mana abilities alone" $ do
    matchup <- BotSpec.bears s registry
    let (outcome, shown) = against plays matchup
        menus = actionMenus shown
    Spec.assertBool s (either (const False) (const True) outcome) ("finished: " <> show (fmap fst outcome))
    Spec.assertEqWith s "menus of passing and mana abilities" (filter (all (\o -> o == Text.pack "Pass" || Text.isPrefixOf (Text.pack "Activate a mana ability of ") o)) menus) []
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Player 1 passes in ")) shown) "passed for"

  Spec.it s "auto pays a cost's color from the land that makes it and its generic from another" $ do
    (lands, resolved, tapped, shown) <- castPaying "auto" s registry "Grizzly Bears" ["Mountain", "Mountain", "Forest"]
    Spec.assertEqWith s "the bear resolved" resolved True
    Spec.assertEqWith s "the Forest and one Mountain tapped" (fmap (`elem` tapped) lands) [True, False, True]
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Paying {1}{G}.")) shown) "asked with the cost"
    Spec.assertBool s (not (any (Text.isPrefixOf (Text.pack "Undone: ")) shown)) "a cast completed is not told undone"

  Spec.it s "CR 734.1 a cast stopped partway is told undone at the caster's next priority" $ do
    (_, resolved, tapped, shown) <- castPaying "stop" s registry "Grizzly Bears" ["Mountain", "Forest"]
    Spec.assertEqWith s "the bear did not resolve, and nothing stayed tapped" (resolved, tapped) (False, [])
    Spec.assertEqWith
      s
      "told once, before the next menu"
      (filter (Text.isPrefixOf (Text.pack "Undone: ")) (takeWhile (not . menuHeading) (drop 1 (dropWhile (/= Text.pack "> stop") shown))))
      [Text.pack "Undone: Cast Grizzly Bears could not be completed (its cost was not paid), so it was reversed and its payments canceled."]

  -- Ebony Charm's modes are asked as JSON (#5225), and no mode is not one.
  Spec.it s "CR 601.2e a cast whose announced modes are illegal is told undone, and why" $ do
    (_, _, tapped, shown) <- castPaying "[]" s registry "Ebony Charm" ["Swamp"]
    Spec.assertEqWith s "nothing stayed tapped" tapped []
    Spec.assertEqWith
      s
      "told once, before the next menu"
      (filter (Text.isPrefixOf (Text.pack "Undone: ")) (takeWhile (not . menuHeading) (drop 1 (dropWhile (/= Text.pack "> []") shown))))
      [Text.pack "Undone: Cast Ebony Charm could not be completed (a choice announced for it was illegal), so it was reversed and its payments canceled."]

  Spec.it s "CR 508.1 / 509.1 a declaration asked again after its cost went unpaid or it broke a restriction is told undone, and why" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (attacker, g1) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
        (blocker, gs) = S.addPermanent piker S.bob g1
        unpaid = gs {GameState.undone = Map.fromList [(S.alice, Undoing.UnpaidCost), (S.bob, Undoing.UnpaidCost)]}
        told seat g prompt = filter (Text.isPrefixOf (Text.pack "Undone: ")) (snd (asking Hotseat.fresh {Hotseat.facing = Just seat} [""] g prompt))
        attacking = Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.alice [attacker]
        blocking = Prompt.DeclareBlockers (Decider.MkDecider S.bob) S.bob [blocker] [attacker]
    Spec.assertEqWith s "the attackers" (told S.alice unpaid attacking) [Text.pack "Undone: The declaration of attackers could not be completed (its cost was not paid), so it was reversed and its payments canceled."]
    Spec.assertEqWith s "the blockers" (told S.bob unpaid blocking) [Text.pack "Undone: The declaration of blockers could not be completed (its cost was not paid), so it was reversed and its payments canceled."]
    Spec.assertEqWith s "a declaration with nothing undone is told nothing" (told S.alice gs attacking) []
    let illegal = gs {GameState.undone = Map.singleton S.alice Undoing.IllegalDeclaration}
    Spec.assertEqWith s "an illegal declaration" (told S.alice illegal attacking) [Text.pack "Undone: The declaration of attackers could not be completed (it broke a restriction or requirement on attacking or blocking), so it was reversed and its payments canceled."]

  Spec.it s "CR 733.3 a cast refused for repeating a loop is told undone, and why" $ do
    let gs = (Setup.emptyGame S.bothPlayers) {GameState.undone = Map.singleton S.alice Undoing.RepeatedLoop}
        view = PlayerView.viewFor S.alice gs
        mark = (PlayerView.Type.game view, PlayerView.Type.turn view, Natural.length (PlayerView.Type.witnessed view))
        tried = Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.attempted = Map.singleton S.alice (mark, Text.pack "Cast Blinking Spirit")}
        shown = snd (asking tried [""] gs (Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass]))
    Spec.assertEqWith
      s
      "told why"
      (filter (Text.isPrefixOf (Text.pack "Undone: ")) shown)
      [Text.pack "Undone: Cast Blinking Spirit could not be completed (it would repeat a loop, so a different choice is needed), so it was reversed and its payments canceled."]

  Spec.it s "CR 702.51a the payment says convoke is coming, and each convoke candidate is listed as the creatures it taps and the mana it leaves" $ do
    (placed, resolved, tapped, shown) <- castTyping (convokes "{2}{G}{G}, Tap three untapped creatures you control" "Siege Wurm") s registry "Siege Wurm" (replicate 4 "Forest" <> replicate 3 "Grizzly Bears")
    Spec.assertEqWith s "the wurm resolved" resolved True
    Spec.assertEqWith s "every land and creature tapped" (fmap (`elem` tapped) placed) (replicate 7 True)
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Paying {5}{G}{G}. After the mana, convoke can pay part of it. Choose a source")) shown) "told convoke is coming"
    Spec.assertEqWith
      s
      "every candidate listed"
      (take 9 (drop 1 (dropWhile (/= Text.pack "Choose how to pay for Siege Wurm:") shown)))
      ( zipWith
          (\i t -> Text.pack ("  " <> show i <> ". " <> t))
          [1 :: Int ..]
          [ "{5}{G}{G}",
            "{5}{G}, Tap an untapped green creature you control",
            "{5}, Tap two untapped green creatures you control",
            "{4}{G}{G}, Tap an untapped creature you control",
            "{4}{G}, Tap an untapped creature you control, Tap an untapped green creature you control",
            "{4}, Tap an untapped creature you control, Tap two untapped green creatures you control",
            "{3}{G}{G}, Tap two untapped creatures you control",
            "{3}{G}, Tap two untapped creatures you control, Tap an untapped green creature you control",
            "{2}{G}{G}, Tap three untapped creatures you control"
          ]
      )

  Spec.it s "CR 734.1 a cast reversed asks whether each mana ability is reversed too, as yes or no" $ do
    (placed, resolved, tapped, shown) <- castTyping (convokes "{5}{G}{G}" "Siege Wurm") s registry "Siege Wurm" (replicate 4 "Forest" <> replicate 3 "Grizzly Bears")
    Spec.assertEqWith s "the wurm did not resolve, and no Forest stayed tapped" (resolved, filter (`elem` tapped) (take 4 placed)) (False, [])
    Spec.assertEqWith s "asked once per Forest" (length (filter (== Text.pack "That action was reversed. Reverse the mana ability of Your Forest (tapped) too?") shown)) 4

  -- The Plateau makes red ahead of white, so taking its first yield fails.
  Spec.it s "auto pays through a dual land, taking the color still owed" $ do
    (lands, resolved, tapped, shown) <- castPaying "auto" s registry "Savannah Lions" ["Taiga", "Plateau"]
    Spec.assertEqWith s "the lions resolved" resolved True
    Spec.assertEqWith s "the Plateau tapped" (fmap (`elem` tapped) lands) [False, True]
    Spec.assertBool s (Text.pack "Auto takes W." `elem` shown) "took white"

  Spec.it s "auto taps the source making the fewest colors still owed, for the color owed" $ do
    gs <- started s registry
    taiga <- S.printingOf s registry "Taiga"
    plateau <- S.printingOf s registry "Plateau"
    let (t, g1) = S.addPermanent taiga S.alice gs
        (p, board) = S.addPermanent plateau S.alice g1
        decider = Decider.MkDecider S.alice
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        cost = ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.Red), ManaSymbol.OfType (ManaType.Colored Color.Green)]
        options = Mana.manaOptionsOf p board
    Spec.assertEqWith s "the Plateau" (fst (asking facing ["auto"] board (Prompt.ChooseManaSource decider S.alice cost (t NonEmpty.:| [p])))) (Right (Just p))
    case options of
      first : rest -> do
        let white = ManaType.Colored Color.White
            yielded = fmap (fmap ManaUnit.manaType . Mana.yieldUnits) (fst (asking facing {Hotseat.paying = Map.singleton S.alice (Set.singleton white)} [] board (Prompt.ChooseManaYield decider S.alice p (first NonEmpty.:| rest))))
        Spec.assertEqWith s "white from the Plateau, its second yield" yielded (Right [white])
      [] -> Spec.assertFailure s "the Plateau makes nothing"

  Spec.it s "auto counts the payer's floating mana against the cost" $ do
    gs <- started s registry
    mountain <- S.printingOf s registry "Mountain"
    forest <- S.printingOf s registry "Forest"
    let (f, g1) = S.addPermanent forest S.alice gs
        (m, g2) = S.addPermanent mountain S.alice g1
        floating = Mana.addMana S.alice [ManaSpec.unitOf (ManaType.Colored Color.Red)] g2
        cost = ManaCost.MkManaCost [ManaSymbol.Generic 1, ManaSymbol.OfType (ManaType.Colored Color.Red)]
        prompt = Prompt.ChooseManaSource (Decider.MkDecider S.alice) S.alice cost (f NonEmpty.:| [m])
    Spec.assertEqWith s "the Forest for the generic, the floating red paying the red" (fst (asking Hotseat.fresh {Hotseat.facing = Just S.alice} ["auto"] floating prompt)) (Right (Just f))

  Spec.it s "a payment shows the payer's pool and what it leaves to pay, and a refused source reprints the sources" $ do
    gs <- started s registry
    mountain <- S.printingOf s registry "Mountain"
    forest <- S.printingOf s registry "Forest"
    let (f, g1) = S.addPermanent forest S.alice gs
        (m, g2) = S.addPermanent mountain S.alice g1
        floating = Mana.addMana S.alice [ManaSpec.unitOf (ManaType.Colored Color.Red)] g2
        cost = ManaCost.MkManaCost [ManaSymbol.Generic 2, ManaSymbol.OfType (ManaType.Colored Color.Green)]
        prompt = Prompt.ChooseManaSource (Decider.MkDecider S.alice) S.alice cost (f NonEmpty.:| [m])
        heading = Text.pack "Paying {2}{G} with {R} in the pool, leaving {1}{G}. Choose a source to pay with, stop to stop paying, or auto (or press Enter) to pay the rest:"
        (picked, shown) = asking Hotseat.fresh {Hotseat.facing = Just S.alice} ["9", "1"] floating prompt
        refusal = dropWhile (/= Text.pack "> 9") shown
    Spec.assertEqWith s "picked after the refusal" picked (Right (Just f))
    Spec.assertBool s (heading `elem` shown) ("the pool and what is left: " <> show shown)
    Spec.assertEqWith s "the sources again after the refusal" (take 3 (drop 2 refusal)) (take 3 (dropWhile (/= heading) shown))

  Spec.it s "auto asks again when it cannot pay the rest of a cost" $ do
    gs <- started s registry
    mountain <- S.printingOf s registry "Mountain"
    let (m, board) = S.addPermanent mountain S.alice gs
        decider = Decider.MkDecider S.alice
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        green = ManaSymbol.OfType (ManaType.Colored Color.Green)
        hybrid = ManaSymbol.Hybrid (Hybrid.MkHybrid (ManaType.Colored Color.Green) (ManaType.Colored Color.White))
        refusal = Text.pack "Auto can't pay the rest of this cost. Choose a source."
        paying cost = Prompt.ChooseManaSource decider S.alice (ManaCost.MkManaCost cost) (m NonEmpty.:| [])
        (unmade, unmadeShown) = asking facing ["auto", "1"] board (paying [green])
        (unread, unreadShown) = asking facing ["auto", "1"] board (paying [hybrid])
    Spec.assertEqWith s "no source makes green" (unmade, refusal `elem` unmadeShown) (Right (Just m), True)
    Spec.assertEqWith s "a hybrid symbol" (unread, refusal `elem` unreadShown) (Right (Just m), True)
    Spec.assertEqWith s "a generic cost" (fst (asking facing ["auto"] board (paying [ManaSymbol.Generic 1]))) (Right (Just m))
    -- An empty log, so the screen shows no news either.
    Spec.assertEqWith
      s
      "floats nothing once covered"
      (asking facing {Hotseat.paying = Map.singleton S.alice Set.empty} [] board {GameState.events = Seq.empty} (Prompt.ChooseExtraManaSource decider S.alice (m NonEmpty.:| [])))
      (Right Nothing, [])
    Spec.assertEqWith
      s
      "spends no life for the seat"
      (asking facing {Hotseat.paying = Map.singleton S.alice Set.empty} [] board {GameState.events = Seq.empty} (Prompt.PayLifeForMana decider S.alice 1 ManaType.Colorless))
      (Right OptionalDecision.Declines, [])

  Spec.it s "a seat's battlefield is grouped lands, creatures, then the rest, each by mana value and name" $ do
    printings <- mapM (S.printingOf s registry) ["Lizard Warrior", "Hill Giant", "Mountain", "Grizzly Bears", "Bad Moon", "Forest", "Raging Goblin", "Plains"]
    let (gs, placed) = List.mapAccumL (\g p -> let (oid, g') = S.addPermanent p S.alice g in (g', oid)) (Setup.emptyGame S.bothPlayers) printings
        tapped = case drop 2 placed of
          mountain : _ -> gs {GameState.objects = Map.adjust (\o -> o {Object.tapped = TapState.Tapped}) mountain (GameState.objects gs)}
          [] -> gs
        shown = filter (Text.isPrefixOf (Text.pack "  ")) (Render.board True (PlayerView.viewFor S.alice tapped))
    Spec.assertEqWith
      s
      "grouped"
      shown
      [ Text.pack "  Lands: Forest, Mountain (tapped), Plains",
        Text.pack "  Creatures: Raging Goblin 1/1, Grizzly Bears 2/2, Hill Giant 3/3, Lizard Warrior 4/2",
        Text.pack "  Other permanents: Bad Moon"
      ]

  Spec.it s "the hand lists lands first, then spells by mana value and name" $ do
    printings <- mapM (S.printingOf s registry) ["Volcanic Hammer", "Mountain", "Hill Giant", "Forest", "Raging Goblin", "Blaze"]
    let gs = List.foldl' (\g p -> snd (S.addObjectIn Zone.Hand p S.alice g)) (Setup.emptyGame S.bothPlayers) printings
    Spec.assertEqWith s "ordered" (Render.hand (PlayerView.viewFor S.alice gs)) [Text.pack "Your hand: Forest, Mountain, Blaze, Raging Goblin 1/1, Volcanic Hammer, Hill Giant 3/3"]

  Spec.it s "CR 400.2 the board shows the cards of another hand or a library the seat may see" $ do
    printings <- mapM (S.printingOf s registry) ["Telepathy", "Future Sight", "Hill Giant", "Forest", "Craw Wurm", "Island"]
    case printings of
      [telepathy, futureSight, giant, forest, wurm, island] -> do
        let gs =
              List.foldl'
                (\g (zone, p, pid) -> snd (S.addObjectIn zone p pid g))
                (Setup.emptyGame S.bothPlayers)
                [ (Zone.Battlefield, telepathy, S.alice),
                  (Zone.Battlefield, futureSight, S.bob),
                  (Zone.Hand, giant, S.bob),
                  (Zone.Hand, forest, S.bob),
                  (Zone.Library, wurm, S.bob),
                  (Zone.Library, island, S.bob)
                ]
            seen pid = filter (Text.isPrefixOf (Text.pack "  Seen")) (Render.board True (PlayerView.viewFor pid gs))
        Spec.assertEqWith s "Telepathy and Future Sight, to alice" (seen S.alice) [Text.pack "  Seen in hand: Forest, Hill Giant 3/3", Text.pack "  Seen in library, top first: Craw Wurm 6/4"]
        Spec.assertEqWith s "bob's own hand stays under Your hand" (seen S.bob) [Text.pack "  Seen in library, top first: Craw Wurm 6/4"]
      _ -> Spec.assertFailure s "six printings"

  Spec.it s "card shows a visible card as it is now, with its printed Oracle text" $ do
    goblin <- S.printingOf s registry "Raging Goblin"
    giant <- S.printingOf s registry "Hill Giant"
    lookUp <- cardsNamed s registry ["Raging Goblin", "Hill Giant"]
    text <- oracleOf s registry "Raging Goblin"
    let (g1, placed) = S.addPermanent goblin S.alice (Setup.emptyGame S.bothPlayers)
        (g2, gs0) = S.addPermanent giant S.alice placed
        gs = gs0 {GameState.objects = Map.adjust (\o -> o {Object.counters = Map.singleton CounterKind.PlusOnePlusOne 1, Object.damage = 1}) g1 (GameState.objects gs0)}
        attacking = Prompt.DeclareAttackers (Decider.MkDecider S.alice) S.alice [g1, g2]
        byName = readout lookUp gs ["card raging goblin", "1"] attacking
        byNumber = readout lookUp gs ["card 2", "1"] attacking
    Spec.assertEqWith s "by name" (cardLines byName) ([Text.pack "Raging Goblin 2/2 (1 damage, 1 +1/+1 counter)", Text.pack "Raging Goblin {R}", Text.pack "Creature \8212 Berserker Goblin", Text.pack "2/2", Text.pack "Counters: 1 +1/+1"] <> Text.lines text)
    Spec.assertBool s (not (null (Text.lines text))) "Raging Goblin has Oracle text"
    Spec.assertBool s (Text.pack "Type card and a number from a list, or a card's name, to read that card." `elem` byName) "the first screen says how"
    Spec.assertEqWith
      s
      "by a bare name the answer does not read"
      (takeWhile (not . Text.isPrefixOf (Text.pack "> ")) (drop 1 (dropWhile (/= Text.pack "> Raging Goblin") (readout lookUp gs ["Raging Goblin", "1"] attacking))))
      (cardLines byName)
    Spec.assertEqWith s "by number" (take 2 (cardLines byNumber)) [Text.pack "Hill Giant 3/3", Text.pack "Hill Giant {3}{R}"]

  Spec.it s "CR 708.2 / 708.5 card shows a face-down permanent's card only to a seat that may look at it" $ do
    tracker <- S.printingOf s registry "Ainok Tracker"
    lookUp <- cardsNamed s registry ["Ainok Tracker"]
    text <- oracleOf s registry "Ainok Tracker"
    let (oid, placed) = S.addPermanent tracker S.bob (Setup.emptyGame S.bothPlayers)
        gs = placed {GameState.objects = Map.adjust (\o -> o {Object.facing = Facing.faceDown FaceDownReason.Morphed}) oid (GameState.objects placed)}
        slot = SlotName.MkSlotName (Text.pack "target")
        targeting pid = Prompt.ChooseTargets (Decider.MkDecider pid) pid oid (Map.singleton slot (1, Set.singleton (Recipient.ToCreature oid)))
        seenBy pid = cardLines (readout lookUp gs ["card 1", "1"] (targeting pid))
    Spec.assertEqWith s "alice sees a nameless 2/2" (seenBy S.alice) [Text.pack "a face-down card 2/2", Text.pack "Creature", Text.pack "2/2"]
    Spec.assertBool s (any (Text.isInfixOf (Text.pack "Ainok Tracker")) (seenBy S.bob) && all (`elem` seenBy S.bob) (Text.lines text)) ("bob looks at it: " <> show (seenBy S.bob))
    Spec.assertEqWith s "alice cannot name it" (cardLines (readout lookUp gs ["card Ainok Tracker", "1"] (targeting S.alice))) [Text.pack "No card you can see is named Ainok Tracker."]

  Spec.it s "a target prompt tells same-named permanents apart by controller and status, the deciding seat's first" $ do
    island <- S.printingOf s registry "Island"
    demolish <- S.printingOf s registry "Demolish"
    let (bobTapped, g1) = S.addPermanent island S.bob (Setup.emptyGame S.bothPlayers)
        (alices, g2) = S.addPermanent island S.alice g1
        (bobs, g3) = S.addPermanent island S.bob g2
        (buried, g4) = S.addObjectIn Zone.Graveyard island S.bob g3
        (spell, g5) = S.addHandCard demolish S.alice g4
        gs = g5 {GameState.objects = Map.adjust (\o -> o {Object.tapped = TapState.Tapped}) bobTapped (GameState.objects g5)}
        slot = SlotName.MkSlotName (Text.pack "target")
        legal = Set.fromList (fmap Recipient.ToObject [bobTapped, alices, bobs, buried])
        prompt = Prompt.ChooseTargets (Decider.MkDecider S.alice) S.alice spell (Map.singleton slot (1, legal))
        (picked, shown) = asking Hotseat.fresh {Hotseat.facing = Just S.alice} ["2"] gs prompt
    Spec.assertEqWith
      s
      "listed"
      (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (not . Text.isPrefixOf (Text.pack "Choose 1 target for Demolish")) shown)))
      [ Text.pack "  1. Your Island",
        Text.pack "  2. Player 2's Island (tapped)",
        Text.pack "  3. Player 2's Island",
        Text.pack "  4. Player 2's Island, in a graveyard"
      ]
    Spec.assertEqWith s "the number picks the one shown" picked (Right (Map.singleton slot (Set.singleton (Recipient.ToObject bobTapped))))
    Spec.assertBool s (Text.pack "Choose 1 target for Demolish:" `elem` shown) "one slot goes unnamed"
    let second = SlotName.MkSlotName (Text.pack "secondTarget")
        twoSlots = Prompt.ChooseTargets (Decider.MkDecider S.alice) S.alice spell (Map.fromList [(slot, (1, legal)), (second, (1, legal))])
        (_, twoShown) = asking Hotseat.fresh {Hotseat.facing = Just S.alice} ["1", "2"] gs twoSlots
    Spec.assertEqWith s "several slots are named as words" (filter (Text.isPrefixOf (Text.pack "Choose 1 target")) twoShown) [Text.pack "Choose 1 target for Demolish (second target):", Text.pack "Choose 1 target for Demolish (target):"]

  Spec.it s "CR 103.5 another seat is told who kept, who mulliganed and how many cards each mulligan bottoms" $ do
    matchup <- BotSpec.bears s registry
    let answer :: Prompt.Prompt r -> r
        answer p = case p of
          Prompt.DeclareMulligan _ pid offer | pid == S.alice && MulliganOffer.taken offer < 2 -> MulliganDecision.Mulligan
          _ -> S.castAnswer p
        gs = snd (Engine.runGamePure answer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup))
        view = PlayerView.viewFor S.bob gs
    Spec.assertEqWith
      s
      "told to Player 2"
      (Render.events view (Render.witnessed view))
      [ Text.pack "Player 1 draws 7 cards.",
        Text.pack "Player 2 draws 7 cards.",
        Text.pack "Player 1 mulligans, bottoming 1 card.",
        Text.pack "Player 2 keeps.",
        Text.pack "Player 1 draws 7 cards.",
        Text.pack "Player 1 mulligans, bottoming 2 cards.",
        Text.pack "Player 1 draws 7 cards.",
        Text.pack "Player 1 keeps."
      ]

  Spec.it s "CR 701.3a / 702.51a / 122.1 each logged entry is told with its subject, a token as created and a move to the stack as nothing" $ do
    gs <- started s registry
    ensoul <- S.printingOf s registry "Ensoul Artifact"
    bears <- S.printingOf s registry "Grizzly Bears"
    totem <- S.printingOf s registry "Living Totem"
    wurm <- S.printingOf s registry "Siege Wurm"
    let (aura, g1) = S.addPermanent ensoul S.alice gs
        (bear, g2) = S.addPermanent bears S.alice g1
        (totemId, g3) = S.addPermanent totem S.alice g2
        (wurmId, board) = S.addPermanent wurm S.alice g3
        soldier = S.emptyCharacteristics {ProjectedCharacteristics.names = Set.singleton (CardName.MkCardName (Text.pack "Soldier Token"))}
        moved from to = GameEvent.Moved (Moved.moved (ZoneChange.MkZoneChange (ObjectId.MkObjectId 90) (ObjectId.MkObjectId 91) from to) soldier) {Moved.seenArriving = True}
        logged =
          [ GameEvent.BecameAttached (BecameAttached.MkBecameAttached aura (Recipient.ToObject bear)),
            GameEvent.BecameUnattached (BecameUnattached.MkBecameUnattached aura (Recipient.ToObject bear)),
            GameEvent.Convoked (Convoking.MkConvoking wurmId (Set.fromList [bear, totemId])),
            GameEvent.CountersPut (CountersPlaced.MkCountersPlaced S.alice wurmId CounterKind.PlusOnePlusOne 0 1),
            moved Zone.Battlefield Zone.Battlefield,
            moved Zone.Hand Zone.Stack
          ]
        witnessing = board {GameState.events = Seq.fromList (fmap (LoggedEvent.MkLoggedEvent (EventGroup.MkEventGroup 0)) logged)}
        view = PlayerView.viewFor S.alice witnessing
    Spec.assertEqWith
      s
      "told"
      (Render.events view (Render.witnessed view))
      [ Text.pack "Ensoul Artifact becomes attached to Grizzly Bears.",
        Text.pack "Ensoul Artifact becomes unattached from Grizzly Bears.",
        Text.pack "Grizzly Bears and Living Totem convoke Siege Wurm.",
        Text.pack "Player 1 puts 1 +1/+1 counter on Siege Wurm.",
        Text.pack "Soldier Token is created."
      ]

  Spec.it s "CR 104.3 the entries that end the game are shown before its result" $ do
    matchup <- BotSpec.bears s registry
    let terminal = screen 3000 plays
        seats = Map.fromList [(S.alice, Game.human terminal (const (Right Nothing))), (S.bob, Game.bot (S.fixtureRegistry []))]
        (outcome, sc) = State.runState (Game.run (S.fixtureRegistry []) [] seats (Client.ending terminal [S.alice]) Hotseat.fresh {Hotseat.facing = Just S.alice} (SplitMix.MkSplitMix 1) Map.empty matchup) blank
        loser = case outcome of
          Right (Result.Won winner, _) -> Just (if winner == S.alice then S.bob else S.alice)
          _ -> Nothing
    Spec.assertBool s (Maybe.isJust loser) ("won: " <> show (fmap fst outcome))
    Spec.assertBool s (any (\pid -> Render.player pid <> Text.pack " loses the game." `elem` pending sc) loser) ("shown after the last answer: " <> show (pending sc))

  Spec.it s "CR 103.5 a mulligan is asked before the first turn, not in its untap step" $ do
    gs <- started s registry
    let offer = MulliganOffer.MkMulliganOffer {MulliganOffer.taken = 0, MulliganOffer.bottomCount = 1}
        (_, shown) = asking Hotseat.fresh {Hotseat.facing = Just S.alice} ["1"] gs (Prompt.DeclareMulligan (Decider.MkDecider S.alice) S.alice offer)
    Spec.assertEqWith s "the heading" (take 1 (drop 1 shown)) [Text.pack "Before the first turn. " <> Render.player (GameState.activePlayer gs) <> Text.pack " plays first."]

  Spec.it s "CR 404.3 a graveyard batch is listed top first; numbers rearrange it, Enter keeps it, and a repeat is refused" $ do
    bears <- S.printingOf s registry "Grizzly Bears"
    giant <- S.printingOf s registry "Hill Giant"
    let (bear, g1) = S.addObjectIn Zone.Graveyard bears S.alice (Setup.emptyGame S.bothPlayers)
        (top, gs) = S.addObjectIn Zone.Graveyard giant S.alice g1
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        prompt = Prompt.ArrangeGraveyardArrivals (Decider.MkDecider S.alice) S.alice [top, bear]
        (rearranged, shown) = asking facing ["2 1"] gs prompt
    Spec.assertEqWith
      s
      "listed"
      (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (not . Text.isPrefixOf (Text.pack "These cards go to your graveyard together.")) shown)))
      [Text.pack "  1. Your Hill Giant 3/3, in a graveyard", Text.pack "  2. Your Grizzly Bears 2/2, in a graveyard"]
    Spec.assertEqWith s "numbers rearrange" rearranged (Right (GraveyardArrangement.InOrder [1, 0]))
    Spec.assertEqWith s "Enter keeps" (fst (asking facing [""] gs prompt)) (Right GraveyardArrangement.AnyOrder)
    Spec.assertEqWith s "a repeat is refused" (fst (asking facing ["1 1"] gs prompt)) (Left (Text.pack "end of input"))
    Spec.assertEqWith s "a card left out is refused" (fst (asking facing ["2"] gs prompt)) (Left (Text.pack "end of input"))

  -- `parun play`'s answer to card data it cannot read: play stops, saying why,
  -- rather than showing the card as one with no text.
  Spec.it s "card stops play, saying why, when the card data cannot be read" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    let (_, gs) = S.addPermanent piker S.alice (Setup.emptyGame S.bothPlayers)
        priority = Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass]
        corpus = InvalidCorpus.MkInvalidCorpus "cards" ["cards/goblin-piker.json: unreadable"]
        reading found = fst (consulting (const found) gs ["card Goblin Piker", "1"] priority)
    Spec.assertEqWith s "play stops, naming the file" (Either.fromLeft Text.empty (reading (Left corpus))) (Text.pack (Exception.displayException corpus))
    Spec.assertBool s (Either.isRight (reading (Right Nothing))) "with no card by that name, play goes on"

  Spec.it s "card shows nothing of a card in another seat's hand" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    lookUp <- cardsNamed s registry ["Goblin Piker"]
    let (_, gs) = S.addObjectIn Zone.Hand piker S.bob (Setup.emptyGame S.bothPlayers)
        priority pid = Prompt.ChooseAction (Decider.MkDecider pid) pid [Action.Pass]
        seenBy pid = cardLines (readout lookUp gs ["card Goblin Piker", "1"] (priority pid))
    Spec.assertEqWith s "alice" (seenBy S.alice) [Text.pack "No card you can see is named Goblin Piker."]
    Spec.assertEqWith s "bob" (take 2 (seenBy S.bob)) [Text.pack "Goblin Piker 2/1", Text.pack "Goblin Piker {1}{R}"]

  Spec.it s "CR 103.1 a seat picked at random from the seed chooses to play first or draw" $ do
    let seeds = [0 .. 15 :: Word.Word64]
        firstWhen answers seed = fst (fst (starting PlayOptions.none answers seed))
        asked seed = written (snd (starting PlayOptions.none [Text.pack "play"] seed))
    Spec.assertEqWith s "the answer decides" (fmap (\seed -> (firstWhen [Text.pack "play"] seed, firstWhen [Text.pack "draw"] seed)) seeds) (fmap (\seed -> let chooser = firstWhen [Text.pack "play"] seed in (chooser, fmap otherSeat chooser)) seeds)
    Spec.assertEqWith s "either seat may be picked" (Set.fromList (fmap (firstWhen [Text.pack "play"]) seeds)) (Set.fromList [Just 1, Just 2])
    Spec.assertBool s (all (\seed -> maybe False (\n -> Text.pack ("Seat " <> show n <> ", play first or draw?") `elem` asked seed) (firstWhen [Text.pack "play"] seed)) seeds) "the picked seat is asked"
    Spec.assertBool s (all (\seed -> snd (fst (starting PlayOptions.none [Text.pack "play"] seed)) /= SplitMix.MkSplitMix seed) seeds) "drawn from the game's generator"
    Spec.assertEqWith s "asked again" (fst (fst (starting PlayOptions.none [Text.pack "first", Text.pack " D "] 3))) (firstWhen [Text.pack "draw"] 3)
    Spec.assertEqWith s "end of input" (fst (fst (starting PlayOptions.none [] 3))) Nothing

  Spec.it s "CR 103.1 --first names the seat that plays first, asking and drawing nothing" $ do
    let ((first, generator), shown) = starting PlayOptions.none {PlayOptions.first = Just 2} [] 5
    Spec.assertEqWith s "first" first (Just 2)
    Spec.assertEqWith s "generator" generator (SplitMix.MkSplitMix 5)
    Spec.assertEqWith s "shown" (written shown) []

  Spec.it s "CR 103.1 a bot picked to choose answers for itself" $ do
    let bots = PlayOptions.none {PlayOptions.bots = Set.fromList [1, 2]}
        runs = fmap (starting bots []) [0 .. 15 :: Word.Word64]
    Spec.assertEqWith s "first" (Set.fromList (fmap (fst . fst) runs)) (Set.fromList [Just 1, Just 2])
    Spec.assertEqWith s "typed" (fmap (typed . snd) runs) (fmap (const 0) runs)
    Spec.assertBool s (any (\((first, _), shown) -> any (\n -> Text.pack ("Seat " <> show (otherSeat n) <> " was picked at random to choose who plays first.") `elem` written shown) first) runs) "the bot sometimes draws"

  Spec.it s "CR 603.3b each trigger to order is listed by its source and Oracle text; numbers order them, Enter keeps the order, and a repeat is refused" $ do
    monk <- S.printingOf s registry "Venerable Monk"
    warden <- S.printingOf s registry "Soul Warden"
    monkCard <- S.cardOf s registry "Venerable Monk"
    wardenCard <- S.cardOf s registry "Soul Warden"
    let (m, g1) = S.addPermanent monk S.alice (Setup.emptyGame S.bothPlayers)
        (w, gs) = S.addPermanent warden S.alice g1
        entriesOf oid card = [TriggerEntry.MkTriggerEntry (TriggerSource.OfObject oid) ability | face <- Foldable.toList (Card.faces card), ability <- Face.triggeredAbilities face]
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        prompt = Prompt.OrderTriggers (Decider.MkDecider S.alice) S.alice (entriesOf m monkCard <> entriesOf w wardenCard)
        (ordered, shown) = asking facing ["2 1"] gs prompt
    Spec.assertEqWith
      s
      "listed"
      (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (not . Text.isPrefixOf (Text.pack "Order your triggered abilities")) shown)))
      [Text.pack "  1. Venerable Monk: When Venerable Monk enters, you gain 2 life.", Text.pack "  2. Soul Warden: Whenever another creature enters, you gain 1 life."]
    Spec.assertEqWith s "numbers order" ordered (Right [1, 0])
    Spec.assertEqWith s "Enter keeps" (fst (asking facing [""] gs prompt)) (Right [0, 1])
    Spec.assertEqWith s "a repeat is refused" (fst (asking facing ["1 1"] gs prompt)) (Left (Text.pack "end of input"))

  Spec.it s "CR 601.2h the mana to spend is listed by type and what sets a unit apart, and the unit picked is spent" $ do
    let plain = Mana.lifeForManaUnit (ManaType.Colored Color.Red)
        snow = plain {ManaUnit.tags = Set.singleton ProductionTag.Snow}
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        prompt = Prompt.ChooseManaToSpend (Decider.MkDecider S.alice) S.alice (plain NonEmpty.:| [snow])
        (spent, shown) = asking facing ["2"] (Setup.emptyGame S.bothPlayers) prompt
    Spec.assertEqWith
      s
      "listed"
      (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (/= Text.pack "Choose the mana to spend:") shown)))
      [Text.pack "  1. {R}", Text.pack "  2. {R} (from a snow source)"]
    Spec.assertEqWith s "the snow unit" spent (Right snow)

  Spec.it s "CR 701.23a / 701.23b a search lists the library cards by name and takes up to its count, Enter for none" $ do
    bears <- S.printingOf s registry "Grizzly Bears"
    giant <- S.printingOf s registry "Hill Giant"
    forest <- S.printingOf s registry "Forest"
    let (b, g1) = S.addObjectIn Zone.Library bears S.alice (Setup.emptyGame S.bothPlayers)
        (g, g2) = S.addObjectIn Zone.Library giant S.alice g1
        (f, gs) = S.addObjectIn Zone.Library forest S.alice g2
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        prompt = Prompt.Search (Decider.MkDecider S.alice) S.alice [b, g, f] 2
        (found, shown) = asking facing ["1 3"] gs prompt
    Spec.assertEqWith
      s
      "listed"
      (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (not . Text.isPrefixOf (Text.pack "Choose up to 2 cards to find")) shown)))
      [Text.pack "  1. Grizzly Bears", Text.pack "  2. Hill Giant", Text.pack "  3. Forest"]
    Spec.assertEqWith s "found" found (Right [b, f])
    Spec.assertEqWith s "Enter finds none" (fst (asking facing [""] gs prompt)) (Right [])
    Spec.assertEqWith s "past the count is refused" (fst (asking facing ["all"] gs prompt)) (Left (Text.pack "end of input"))

  Spec.it s "CR 608.2d a prompt answered by one of a list numbers its options, and the number picks one" $ do
    bears <- S.printingOf s registry "Grizzly Bears"
    giant <- S.printingOf s registry "Hill Giant"
    forest <- S.printingOf s registry "Forest"
    let (b, g1) = S.addHandCard bears S.alice (Setup.emptyGame S.bothPlayers)
        (g, g2) = S.addHandCard giant S.alice g1
        (f, gs) = S.addPermanent forest S.alice g2
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        alice = Decider.MkDecider S.alice
        listedAfter heading screenLines = takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (/= Text.pack heading) screenLines))
        (card, shown) = asking facing ["2"] gs (Prompt.ChooseCardInHand alice S.alice f (b NonEmpty.:| [g]))
        (player, seats) = asking facing ["2"] gs (Prompt.ChoosePlayer alice S.alice f (S.alice NonEmpty.:| [S.bob]))
        (assistant, declining) = asking facing ["2"] gs (Prompt.ChooseAssistant alice S.alice f (S.bob NonEmpty.:| []))
    Spec.assertEqWith s "cards listed" (listedAfter "Choose card in hand for Forest:" shown) [Text.pack "  1. Grizzly Bears", Text.pack "  2. Hill Giant"]
    Spec.assertEqWith s "the card picked" card (Right g)
    Spec.assertEqWith s "seats listed" (listedAfter "Choose player for Forest:" seats) [Text.pack "  1. Player 1", Text.pack "  2. Player 2"]
    Spec.assertEqWith s "the seat picked" player (Right S.bob)
    Spec.assertEqWith s "declining listed last" (listedAfter "Choose assistant for Forest:" declining) [Text.pack "  1. Player 2", Text.pack "  2. None"]
    Spec.assertEqWith s "declined" assistant (Right Nothing)
    Spec.assertEqWith s "past the list is refused" (fst (asking facing ["3"] gs (Prompt.ChooseCardInHand alice S.alice f (b NonEmpty.:| [g])))) (Left (Text.pack "end of input"))

  Spec.it s "CR 401.4 a prompt answered by a permutation numbers what it orders, and the numbers first to last order it" $ do
    bears <- S.printingOf s registry "Grizzly Bears"
    giant <- S.printingOf s registry "Hill Giant"
    forest <- S.printingOf s registry "Forest"
    let (b, g1) = S.addHandCard bears S.alice (Setup.emptyGame S.bothPlayers)
        (g, g2) = S.addPermanent giant S.alice g1
        (f, gs) = S.addPermanent forest S.alice g2
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        alice = Decider.MkDecider S.alice
        listedAfter heading screenLines = takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (/= Text.pack heading) screenLines))
        arrange = Prompt.ArrangeLibraryArrivals alice S.alice LibraryPosition.Top [b, g]
        (reordered, shown) = asking facing ["2 1"] gs arrange
        hit target n = DamageEvent.MkDamageEvent f target n False False False 0 Nothing Nothing mempty False mempty DamageKind.Noncombat
        (_, damage) = asking facing [""] gs (Prompt.OrderDamage alice S.alice [hit (Recipient.ToPlayer S.bob) 2, hit (Recipient.ToCreature g) 3])
    Spec.assertEqWith s "cards listed, the first going on top" (listedAfter "Arrange library arrivals: type their numbers first to last, separated by spaces, or press Enter to keep this order; the first goes on top:" shown) [Text.pack "  1. Grizzly Bears", Text.pack "  2. Your Hill Giant 3/3"]
    Spec.assertEqWith s "the order typed" reordered (Right [1, 0])
    Spec.assertEqWith s "Enter keeps the order shown" (fst (asking facing [""] gs arrange)) (Right [0, 1])
    Spec.assertEqWith s "a number twice is refused" (fst (asking facing ["1 1"] gs arrange)) (Left (Text.pack "end of input"))
    Spec.assertEqWith s "damage events listed" (listedAfter "Order damage: type their numbers first to last, separated by spaces, or press Enter to keep this order; the first goes first:" damage) [Text.pack "  1. Forest deals 2 damage to Player 2", Text.pack "  2. Forest deals 3 damage to Your Hill Giant 3/3"]

  Spec.it s "CR 702.136a riot is offered as yes or no through the client, and yes enters the creature with its counter" $ do
    let heading = Text.pack "Choose riot for Zhur-Taa Goblin:"
        riots sc
          | heading `elem` pending sc = Just (Text.pack "1")
          | otherwise = castsOnce "auto" "Zhur-Taa Goblin" sc
    (_, resolved, _, shown) <- castTyping riots s registry "Zhur-Taa Goblin" ["Mountain", "Forest"]
    Spec.assertEqWith s "yes and no listed" (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (/= heading) shown))) [Text.pack "  1. Yes", Text.pack "  2. No"]
    Spec.assertBool s resolved "resolved"
    Spec.assertBool s (any (\l -> Text.isPrefixOf (Text.pack "  Creatures: ") l && Text.isInfixOf (Text.pack "Zhur-Taa Goblin 3/3") l) shown) "entered with its counter"

  Spec.it s "CR 608.2d a prompt answered by one of a fixed set lists it, after what the offer tells" $ do
    forest <- S.printingOf s registry "Forest"
    giant <- S.printingOf s registry "Hill Giant"
    let (f, g1) = S.addPermanent forest S.alice (Setup.emptyGame S.bothPlayers)
        (g, gs) = S.addPermanent giant S.bob g1
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        alice = Decider.MkDecider S.alice
        upTo heading screenLines = takeWhile (\l -> not (any (`Text.isPrefixOf` l) [Text.pack "Type ", Text.pack "> "])) (dropWhile (not . Text.isPrefixOf heading) screenLines)
        cost = Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 3])) []
        (paid, life) = asking facing ["2"] gs (Prompt.ChoosePayLifeOnEntry alice S.alice f 2)
        (_, buyback) = asking facing [""] gs (Prompt.ChooseBuyback alice S.alice f cost)
        (end, clash) = asking facing ["2"] gs (Prompt.ChooseClash alice S.alice f f ((S.alice, f) NonEmpty.:| [(S.bob, g)]) (Seq.singleton (S.bob, LibraryPosition.Top)))
    Spec.assertEqWith s "life told, then yes or no" (upTo (Text.pack "Life: ") life) (fmap Text.pack ["Life: 2", "Choose pay life on entry for Forest:", "  1. Yes", "  2. No"])
    Spec.assertEqWith s "declined" paid (Right OptionalDecision.Declines)
    Spec.assertEqWith s "the cost as Oracle text prints it, and a tag as words" (upTo (Text.pack "Cost: ") buyback) (fmap Text.pack ["Cost: {3}", "Choose buyback for Forest:", "  1. Buys back", "  2. No"])
    Spec.assertEqWith s "CR 701.30c / 101.4b the cards revealed and what earlier clashers chose, beside who" (upTo (Text.pack "Card: ") clash) (fmap Text.pack ["Card: Your Forest", "Revealed: Player 1: Your Forest; Player 2: Player 2's Hill Giant 3/3", "Earlier: Player 2: Top", "Choose clash for Forest:", "  1. Top", "  2. Bottom"])
    Spec.assertEqWith s "the end picked" end (Right LibraryPosition.Bottom)
    let hybrid = ManaSymbol.Hybrid (Hybrid.MkHybrid (ManaType.Colored Color.White) (ManaType.Colored Color.Blue))
        (_, half) = asking facing ["1"] gs (Prompt.AnnounceHybridHalf alice S.alice f hybrid (ManaType.Colored Color.White NonEmpty.:| [ManaType.Colored Color.Blue]))
    Spec.assertEqWith s "CR 601.2b a mana symbol as Oracle text prints it" (take 1 (upTo (Text.pack "Symbol: ") half)) [Text.pack "Symbol: {W/U}"]
    let (_, payment) = asking facing ["1"] gs (Prompt.AnnounceHybridPayment alice S.alice f (ManaType.Colored Color.Black) (HybridPayment.PaysTyped NonEmpty.:| [HybridPayment.PaysGeneric]))
    Spec.assertEqWith s "a mana type as its symbol, and tags as words" (upTo (Text.pack "Mana: ") payment) (fmap Text.pack ["Mana: B", "Announce hybrid payment for Forest:", "  1. Pays typed", "  2. Pays generic"])

  -- CR 201.4: a seat at the terminal types a card's name; an empty line is
  -- refused.
  Spec.it s "CR 201.4 a person names a card by typing its name" $ do
    let facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        naming = Prompt.ChooseCardName (Decider.MkDecider S.alice) S.alice (ObjectId.MkObjectId 7) (Filter.Type.And []) Seq.empty
        (named, shown) = asking facing ["", "Goblin Piker"] (Setup.emptyGame S.bothPlayers) naming
    Spec.assertEqWith s "the name typed" named (Right (CardName.MkCardName (Text.pack "Goblin Piker")))
    Spec.assertBool s (Text.pack "Choose a card name: type the name of a card." `elem` shown) "asked for a name"
    Spec.assertBool s (Text.pack "Type the name of a card." `elem` shown) "an empty line refused"

  -- CR 201.4 / 201.4a / 108.1: Null Chamber's two names, each chosen by a bot
  -- seat through Game.consulting over a reference of Plains, Goblin Piker and
  -- Cancel. Plains is refused by the card's restriction and asked again, so
  -- each seat names one of the other two, each over the seeds; each name is
  -- looked up in that reference.
  Spec.it s "CR 201.4 a bot seat names a card the reference holds and the restriction allows" $ do
    plains <- S.printingOf s registry "Plains"
    mountain <- S.printingOf s registry "Mountain"
    nullChamber <- S.printingOf s registry "Null Chamber"
    reference <- mapM (S.cardOf s registry) ["Plains", "Goblin Piker", "Cancel"]
    let (oid, board) = CastProhibitionSpec.nullChamberBoard plains mountain nullChamber
        fixture :: Registry.Registry Identity.Identity
        fixture = S.fixtureRegistry reference
        seats = Map.fromList [(S.alice, Game.bot fixture), (S.bob, Game.bot fixture)]
        answer :: Asked.Asked GameState.GameState r -> Game.Play Identity.Identity r
        answer asked = case Asked.prompt asked of
          Prompt.ChooseCardName {} -> Answerer.unwrap (Game.consulting fixture seats) asked
          Prompt.LookUpCard {} -> Answerer.unwrap (Game.consulting fixture seats) asked
          p -> pure (CastProhibitionSpec.chamberAnswer S.bob (const (CardName.MkCardName Text.empty)) p)
        played seed = Identity.runIdentity (Except.runExceptT (State.evalStateT (State.evalStateT (Engine.runGameAsked answer board (S.cast S.alice oid >> Stack.resolveTop)) (SplitMix.MkSplitMix seed)) Hotseat.fresh))
        chosen seed = case played seed of
          Right (_, after) -> do
            chamber <- CastProhibitionSpec.enteredOne board after >>= (`Game.Engine.lookupObject` after)
            Just (Map.findWithDefault Map.empty Acquisition.Own (Object.chosenNames chamber), Game.Engine.referenceFaces after)
          Left _ -> Nothing
        runs = fmap chosen [1 .. 32 :: Word.Word64]
        allowed = Set.fromList (fmap CardName.MkCardName [Text.pack "Goblin Piker", Text.pack "Cancel"])
        namedBy pid = Set.fromList [name | Just (names, _) <- runs, Just name <- [Map.lookup pid names]]
    Spec.assertBool s (all Maybe.isJust runs) "Null Chamber reached the battlefield every time"
    Spec.assertEqWith s "alice named each allowed name, and only those" (namedBy S.alice) allowed
    Spec.assertEqWith s "bob named each allowed name, and only those" (namedBy S.bob) allowed
    Spec.assertBool s (and [all (`Map.member` faces) (Map.elems names) | Just (names, faces) <- runs]) "CR 108.1 each name was looked up in the reference"

  Spec.it s "CR 701.21a a sacrifice cost is offered through the client as a numbered list, and the number picks what is sacrificed" $ do
    gs <- started s registry
    swamp <- S.printingOf s registry "Swamp"
    bears <- S.printingOf s registry "Grizzly Bears"
    giant <- S.printingOf s registry "Hill Giant"
    rites <- S.printingOf s registry "Village Rites"
    let board = snd (S.addHandCard rites S.alice (List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs [swamp, bears, giant]))
        heading = Text.pack "Choose sacrifices for Village Rites: choose exactly 1, by number or range such as 1-3, separated by spaces:"
        listed at = takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (/= heading) (pending at)))
        sacrifices at
          | heading `elem` pending at = Maybe.listToMaybe [n | line <- listed at, Text.isInfixOf (Text.pack "Hill Giant") line, let n = Text.takeWhile Char.isDigit (Text.strip line)]
          | otherwise = castsOnce "auto" "Village Rites" at
        onBattlefield name = S.countOnBattlefieldByName (CardName.MkCardName (Text.pack name)) S.alice
        seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 sacrifices) (const (Right Nothing)))) botOrDefault
        run = Driver.drive [] seats 40 (pure . (== 0) . onBattlefield "Hill Giant") board
        (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank
        shown = reverse (written sc)
    Spec.assertEqWith s "both creatures listed" (List.sort (fmap (Text.drop 5) (takeWhile (Text.isPrefixOf (Text.pack "  ")) (drop 1 (dropWhile (/= heading) shown))))) (fmap Text.pack ["Your Grizzly Bears 2/2", "Your Hill Giant 3/3"])
    Spec.assertEqWith s "the creature picked was sacrificed, and only it" (fmap (\after -> (onBattlefield "Hill Giant" after, onBattlefield "Grizzly Bears" after)) outcome) (Right (0, 1))

  Spec.it s "CR 608.2d a prompt answered by a set lists its candidates within their bounds, and refuses a pick outside them" $ do
    forest <- S.printingOf s registry "Forest"
    bears <- S.printingOf s registry "Grizzly Bears"
    giant <- S.printingOf s registry "Hill Giant"
    let (f, g1) = S.addPermanent forest S.alice (Setup.emptyGame S.bothPlayers)
        (b, g2) = S.addPermanent bears S.alice g1
        (g, gs) = S.addPermanent giant S.alice g2
        facing = Hotseat.fresh {Hotseat.facing = Just S.alice}
        alice = Decider.MkDecider S.alice
        upTo prefix screenLines = takeWhile (\l -> not (any (`Text.isPrefixOf` l) [Text.pack "Type ", Text.pack "> "])) (dropWhile (not . Text.isPrefixOf prefix) screenLines)
        crew = Prompt.ChooseTapsForTotalPower alice S.alice f [b, g] 3
        (crewed, crewShown) = asking facing ["1-2"] gs crew
        taps = Prompt.ChooseTaps alice S.alice f [b, g] 1
    Spec.assertEqWith s "CR 702.122a the power told, then any number" (upTo (Text.pack "Power: ") crewShown) (fmap Text.pack ["Power: 3", "Choose taps for total power for Forest: choose any number, by number or range such as 1-3, separated by spaces, or press Enter for none:", "  1. Your Grizzly Bears 2/2", "  2. Your Hill Giant 3/3"])
    Spec.assertEqWith s "a range picks both" crewed (Right (Set.fromList [b, g]))
    Spec.assertEqWith s "CR 701.59a the mana value told, in words" (take 1 (upTo (Text.pack "Mana value: ") (snd (asking facing [""] gs (Prompt.ChooseCollectEvidence alice S.alice f [b, g] 4))))) [Text.pack "Mana value: 4"]
    Spec.assertEqWith s "an exact count refuses one too many" (fst (asking facing ["1 2"] gs taps)) (Left (Text.pack "end of input"))
    Spec.assertEqWith s "and takes the count" (fst (asking facing ["2"] gs taps)) (Right (Set.singleton g))
    Spec.assertEqWith s "a most refuses past it" (fst (asking facing ["all"] gs (Prompt.ChooseAnyNumber alice S.alice f AnyNumberOf.ToSacrifice [b, g] (Just 1) Seq.empty))) (Left (Text.pack "end of input"))
    Spec.assertEqWith s "and takes none" (fst (asking facing [""] gs (Prompt.ChooseAnyNumber alice S.alice f AnyNumberOf.ToSacrifice [b, g] (Just 1) Seq.empty))) (Right Set.empty)

-- The seat across the table.
otherSeat :: Natural -> Natural
otherSeat n = if n == 1 then 2 else 1

-- Game.starter from this seed, a person typing these lines in turn: the seat
-- that plays first and the generator after, and the screen.
starting :: PlayOptions.PlayOptions -> [Text.Text] -> Word.Word64 -> ((Maybe Natural, SplitMix.SplitMix), Screen)
starting options answers seed =
  State.runState (State.runStateT (Game.starter (Terminal.say terminal) (Game.playOrDraw terminal) options) (SplitMix.MkSplitMix seed)) blank
  where
    terminal = screen (List.genericLength answers) (\sc -> Maybe.listToMaybe (List.genericDrop (typed sc) answers))

-- What the screen showed, newest first, and how many lines were typed.
data Screen = MkScreen {written :: [Text.Text], typed :: Natural}

blank :: Screen
blank = MkScreen [] 0

-- A person who answers from what the screen shows, stopping after a budget of
-- lines.
screen :: Natural -> (Screen -> Maybe Text.Text) -> Terminal.Terminal (State.State Screen)
screen budget typist =
  Terminal.MkTerminal
    { Terminal.say = \line -> State.modify' (\sc -> sc {written = line : written sc}),
      Terminal.listen = do
        sc <- State.get
        let reply = if typed sc >= budget then Nothing else typist sc
        State.put sc {written = maybe (Text.pack "<eof>") (Text.pack "> " <>) reply : written sc, typed = typed sc + 1}
        pure reply,
      Terminal.clear = State.modify' (\sc -> sc {written = Text.pack "<clear>" : written sc})
    }

-- The bot for each seat no person holds; every other prompt gets its default
-- answer.
botOrDefault :: (Monad m) => Answerer.Answerer (Asked.Asked GameState.GameState) (State.StateT SplitMix.SplitMix m)
botOrDefault = Driver.seated (Bot.bot []) (Answerer.MkAnswerer (pure . Replay.defaultAnswer . Asked.prompt))

-- Alice at the terminal, the bot as bob.
against :: (Screen -> Maybe Text.Text) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> (Either Text.Text (Result.Result, GameState.GameState), [Text.Text])
against typist matchup =
  let seats = Map.fromList [(S.alice, Game.human (screen 3000 typist) (const (Right Nothing))), (S.bob, Game.bot (S.fixtureRegistry []))]
      (outcome, sc) = State.runState (Game.run (S.fixtureRegistry []) [] seats (const (pure ())) Hotseat.fresh {Hotseat.facing = Just S.alice} (SplitMix.MkSplitMix 1) Map.empty matchup) blank
   in (outcome, reverse (written sc))

-- Since the last line typed.
pending :: Screen -> [Text.Text]
pending = reverse . takeWhile (not . Text.isPrefixOf (Text.pack "> ")) . written

typedYet :: String -> Screen -> Bool
typedYet line = elem (Text.pack ("> " <> line)) . written

-- Plays a land or casts a spell when it can, attacks with its first creature,
-- never blocks, pays with the first source, puts all of a divided combat
-- damage on the first recipient, and keeps its hand.
plays :: Screen -> Maybe Text.Text
plays sc
  | any (Text.isPrefixOf (Text.pack "Pass to ")) shown = Just Text.empty
  | any (Text.isPrefixOf (Text.pack "Type the answer as JSON")) shown = Nothing
  | Just n <- Maybe.listToMaybe (Maybe.mapMaybe wanted shown) = Just (Text.unwords (fmap (Text.pack . show) [1 .. n]))
  | any (Text.isPrefixOf (Text.pack "Type blocker:attacker")) shown = Just Text.empty
  | Just total <- Maybe.listToMaybe (Maybe.mapMaybe divided shown) =
      Just (Text.unwords (total : replicate (length (Maybe.mapMaybe option shown) - 1) (Text.pack "0")))
  | any menuHeading shown =
      let options = Maybe.mapMaybe option shown
          pick = List.find (\(_, t) -> any (`Text.isPrefixOf` t) [Text.pack "Play ", Text.pack "Cast "]) options
       in fmap fst (Monad.mplus pick (List.find ((== Text.pack "Pass") . snd) options))
  | Just least <- Maybe.listToMaybe (Maybe.mapMaybe leastX shown) = Just least
  | any (Text.isPrefixOf (Text.pack "The cost is covered.")) shown = Just Text.empty
  | otherwise = Just (Text.pack "1")
  where
    shown = pending sc
    wanted line = case Text.words line of
      choose : n : noun : _
        | choose == Text.pack "Choose", any (`Text.isPrefixOf` noun) [Text.pack "card", Text.pack "target"] -> Read.readMaybe (Text.unpack n) :: Maybe Natural
      _ -> Nothing
    option line = case Text.breakOn (Text.pack ". ") (Text.strip line) of
      (n, rest) | Just _ <- (Read.readMaybe (Text.unpack n) :: Maybe Natural), not (Text.null rest) -> Just (n, Text.drop 2 rest)
      _ -> Nothing
    divided line
      | Text.isPrefixOf (Text.pack "Divide ") line = Maybe.listToMaybe (reverse (takeWhile (/= Text.pack "damage,") (Text.words line)))
      | otherwise = Nothing
    leastX line
      | Text.isPrefixOf (Text.pack "Choose X") line = Maybe.listToMaybe (drop 1 (dropWhile (/= Text.pack "from") (Text.words line)))
      | otherwise = Nothing

-- Each board's "(you)" seat, against the seat last passed to.
mismatches :: [Text.Text] -> [(Text.Text, Text.Text)]
mismatches = go Nothing
  where
    go passed remaining = case remaining of
      [] -> []
      l : rest
        | Just seat <- Text.stripSuffix (Text.pack ", then press Enter.") =<< Text.stripPrefix (Text.pack "Pass to ") l -> go (Just seat) rest
        | (you, after) <- Text.breakOn (Text.pack " (you)") l,
          not (Text.null after),
          Just you /= passed ->
            (you, Maybe.fromMaybe Text.empty passed) : go passed rest
        | otherwise -> go passed rest

-- One prompt answered at a screen in `hotseat` by typing `typing` in turn, then
-- the end of input; the answer, and what the screen showed.
asking :: Hotseat.Hotseat -> [String] -> GameState.GameState -> Prompt.Prompt r -> (Either Text.Text r, [Text.Text])
asking hotseat typing gs prompt =
  let typist now = fmap Text.pack (Maybe.listToMaybe (List.genericDrop (typed now) typing))
      terminal = screen (List.genericLength typing) typist
      (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap (Game.human terminal (const (Right Nothing))) (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) hotseat)) blank
   in (outcome, reverse (written sc))

-- Alice casting a creature spell from a game after setup and the named lands,
-- typing this word at each payment: the lands, whether it resolved, which
-- lands it tapped, and what the screen showed.
castPaying :: (Monad m) => String -> Spec.Spec m n -> Registry.Registry m -> String -> [String] -> m ([ObjectId.ObjectId], Bool, [ObjectId.ObjectId], [Text.Text])
castPaying word s registry spell = castTyping (castsOnce word spell) s registry spell

-- castPaying, alice answering as this typist does.
castTyping :: (Monad m) => (Screen -> Maybe Text.Text) -> Spec.Spec m n -> Registry.Registry m -> String -> [String] -> m ([ObjectId.ObjectId], Bool, [ObjectId.ObjectId], [Text.Text])
castTyping typist s registry spell names = do
  gs <- started s registry
  printings <- mapM (S.printingOf s registry) names
  card <- S.printingOf s registry spell
  let place (placed, g) printing = let (oid, g') = S.addPermanent printing S.alice g in (placed <> [oid], g')
      (lands, withLands) = List.foldl' place ([], gs) printings
      board = snd (S.addHandCard card S.alice withLands)
      bears = S.countOnBattlefieldByName (CardName.MkCardName (Text.pack spell)) S.alice
      seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 typist) (const (Right Nothing)))) botOrDefault
      run = Driver.drive [] seats 20 (pure . (> bears board) . bears) board
      (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank
      -- A game that stopped is read as the board it started from.
      after = Either.fromRight board outcome
      tapped = [oid | oid <- lands, fmap Object.tapped (Map.lookup oid (GameState.objects after)) == Just TapState.Tapped]
  pure (lands, bears after > bears board, tapped, reverse (written sc))

-- A game after setup with a Forest under alice's control.
withForest :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (ObjectId.ObjectId, GameState.GameState)
withForest s registry = do
  gs <- started s registry
  forest <- S.printingOf s registry "Forest"
  pure (S.addPermanent forest S.alice gs)

-- Casts the first of the spell it is offered, typing this word at its
-- payment or at a question answered as JSON, and passes otherwise.
castsOnce :: String -> String -> Screen -> Maybe Text.Text
castsOnce word spell sc
  | any (Text.isPrefixOf (Text.pack "Paying ")) shown = Just (Text.pack word)
  | Text.pack "Type the answer as JSON:" `elem` shown = Just (Text.pack word)
  | any menuHeading shown =
      let options = [(n, rest) | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], Text.all (`elem` ['0' .. '9']) n, not (Text.null n)]
          cast = [n | not (typedYet word sc), (n, rest) <- options, rest == Text.pack (". Cast " <> spell)]
       in Maybe.listToMaybe (cast <> [n | (n, rest) <- options, rest == Text.pack ". Pass"])
  | otherwise = plays sc
  where
    shown = pending sc

-- Casts the spell as castsOnce does, paying with auto, choosing the cost
-- listed as this, and reversing every mana ability a reversed cast asks about.
convokes :: String -> String -> Screen -> Maybe Text.Text
convokes wanted spell sc
  | any (Text.isPrefixOf (Text.pack "Choose how to pay for ")) shown = Maybe.listToMaybe [n | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], not (Text.null n), Text.all (`elem` ['0' .. '9']) n, rest == Text.pack (". " <> wanted)]
  | any (Text.isPrefixOf (Text.pack "That action was reversed.")) shown = Just (Text.pack "1")
  | otherwise = castsOnce "auto" spell sc
  where
    shown = pending sc

-- Passes, declares no attackers or blockers, and discards Hill Giant.
discardsGiant :: Screen -> Maybe Text.Text
discardsGiant sc
  | any (Text.isPrefixOf (Text.pack "Pass to ")) shown = Just Text.empty
  | any (Text.isPrefixOf (Text.pack "Choose 1 card to discard")) shown = numberOf ". Hill Giant"
  | any menuHeading shown = numberOf ". Pass"
  | otherwise = Just Text.empty
  where
    shown = pending sc
    numberOf wanted = Maybe.listToMaybe [n | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], not (Text.null n), Text.all (`elem` ['0' .. '9']) n, rest == Text.pack wanted]

-- Activates Mindslaver targeting Player 2 and pays with auto; otherwise as
-- discardsGiant, discarding the first card listed when Hill Giant is not.
slavesBob :: Screen -> Maybe Text.Text
slavesBob sc
  | any (Text.isPrefixOf (Text.pack "Paying ")) shown = Just (Text.pack "auto")
  | any (Text.isPrefixOf (Text.pack "Choose 1 target for ")) shown = numberOf ". Player 2"
  -- Tap, then sacrifice: the order shown.
  | Text.pack "Order cost components for Mindslaver: type their numbers first to last, separated by spaces, or press Enter to keep this order; the first is paid first:" `elem` shown = Just Text.empty
  | any menuHeading shown, Just n <- numberOf ". Activate ability 1 of Mindslaver" = Just n
  | any (Text.isPrefixOf (Text.pack "Choose 1 card to discard")) shown = Monad.mplus (numberOf ". Hill Giant") (Just (Text.pack "1"))
  | otherwise = discardsGiant sc
  where
    shown = pending sc
    numberOf wanted = Maybe.listToMaybe [n | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], not (Text.null n), Text.all (`elem` ['0' .. '9']) n, rest == Text.pack wanted]

-- Casts Illicit Auction for Hill Giant, paying with auto, and bids 3, then 2
-- and 4 once refused, then 4; otherwise as discardsGiant.
bids :: Screen -> Maybe Text.Text
bids sc
  | any (Text.isPrefixOf (Text.pack "Pass to ")) shown = Just Text.empty
  | any (Text.isPrefixOf (Text.pack "Paying ")) shown = Just (Text.pack "auto")
  | any (Text.isPrefixOf (Text.pack "Choose 1 target for Illicit Auction")) shown = numberOf (Text.isInfixOf (Text.pack "Hill Giant"))
  | Text.pack "Type a number of at least 3." `elem` shown = Just (Text.pack "4")
  | Text.pack "Choose a number for Illicit Auction, at least 0; 0 lets the high bid stand:" `elem` shown = Just (Text.pack "3")
  | Text.pack "Choose a number for Illicit Auction, at least 3; 3 lets the high bid stand:" `elem` shown = Just (Text.pack "2")
  | Text.pack "Choose a number for Illicit Auction, at least 4; 4 lets the high bid stand:" `elem` shown = Just (Text.pack "4")
  | any menuHeading shown, Just n <- numberOf (== Text.pack ". Cast Illicit Auction") = Just n
  | otherwise = discardsGiant sc
  where
    shown = pending sc
    numberOf wanted = Maybe.listToMaybe [n | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], not (Text.null n), Text.all (`elem` ['0' .. '9']) n, wanted rest]

-- The lines shown while the screen faced the seat each such hand-off line
-- passes it to.
facedBy :: Text.Text -> [Text.Text] -> [Text.Text]
facedBy handOff shown = case dropWhile (not . Text.isPrefixOf handOff) shown of
  [] -> []
  _ : rest ->
    let (here, later) = break (Text.isPrefixOf (Text.pack "Pass to ")) rest
     in here <> facedBy handOff later

-- An action menu's heading, whether or not it offers Enter to pass.
menuHeading :: Text.Text -> Bool
menuHeading = Text.isPrefixOf (Text.pack "Choose an action")

-- Each action menu shown, by its options.
actionMenus :: [Text.Text] -> [[Text.Text]]
actionMenus shown = case dropWhile (not . menuHeading) shown of
  [] -> []
  _ : rest ->
    let (menu, after) = span (Text.isPrefixOf (Text.pack "  ")) rest
     in fmap (Text.drop 2 . snd . Text.breakOn (Text.pack ". ")) menu : actionMenus after

-- One prompt answered by alice typing one line.
answering :: GameState.GameState -> String -> Prompt.Prompt r -> Either Text.Text r
answering gs line prompt =
  State.evalState
    (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap (Game.human (screen 1 (const (Just (Text.pack line)))) (const (Right Nothing))) (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Driver.deciderOf prompt}))
    blank

-- What one prompt showed its seat, the lines typed one after another.
readout :: (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> GameState.GameState -> [String] -> Prompt.Prompt r -> [Text.Text]
readout lookUp gs typing prompt = snd (consulting lookUp gs typing prompt)

-- readout's run, with its answer or why play stopped.
consulting :: (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> GameState.GameState -> [String] -> Prompt.Prompt r -> (Either Text.Text r, [Text.Text])
consulting lookUp gs typing prompt =
  let typist now = fmap Text.pack (Maybe.listToMaybe (List.genericDrop (typed now) typing))
      human = Game.human (screen (Natural.length typing) typist) lookUp
      (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap human (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Driver.deciderOf prompt, Hotseat.autoPass = False})) blank
   in (outcome, reverse (written sc))

-- What the first "card" line typed showed.
cardLines :: [Text.Text] -> [Text.Text]
cardLines = takeWhile (not . Text.isPrefixOf (Text.pack "> ")) . drop 1 . dropWhile (not . Text.isPrefixOf (Text.pack "> card"))

-- The card data for these cards, by each face's name.
cardsNamed :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> [String] -> m (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card))
cardsNamed s registry names = do
  cards <- mapM (S.cardOf s registry) names
  let byName = Map.fromList [(Face.name f, card) | card <- cards, f <- Foldable.toList (Card.faces card)]
  pure (Right . (`Map.lookup` byName))

-- A one-faced card's printed Oracle text.
oracleOf :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> String -> m Text.Text
oracleOf s registry name = fmap (foldMap (Maybe.fromMaybe Text.empty . Face.oracleText) . Card.faces) (S.cardOf s registry name)

-- A game after setup: alice red, bob green, hands drawn.
started :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m GameState.GameState
started s registry = do
  matchup <- BotSpec.bears s registry
  pure (snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup)))
