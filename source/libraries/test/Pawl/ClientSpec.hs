{-# LANGUAGE GADTs #-}

-- Covers Pawl.Play.Client, Pawl.Play.Render and Pawl.Play.Game: a person at
-- a terminal playing through request lines, against the bot or another
-- person on the same screen.
module Pawl.ClientSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Either as Either
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.BotSpec as BotSpec
import qualified Pawl.Engine.Binding as Binding
import qualified Pawl.Engine.Driver as Driver
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Game as Game.Engine
import qualified Pawl.Engine.Mana as Mana
import qualified Pawl.Engine.PlayerView as PlayerView
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Extra.Natural as Natural
import qualified Pawl.ManaSpec as ManaSpec
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Game as Game
import qualified Pawl.Play.Render as Render
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.BeginningStep as BeginningStep
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.ClauseIndex as ClauseIndex
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.Drew as Drew
import qualified Pawl.Types.EventGroup as EventGroup
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.FaceDownReason as FaceDownReason
import qualified Pawl.Types.Facing as Facing
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.Hybrid as Hybrid
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.ManaUnit as ManaUnit
import qualified Pawl.Types.ModeIndex as ModeIndex
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.OptionalDecision as OptionalDecision
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.RevealCause as RevealCause
import qualified Pawl.Types.Revealed as Revealed
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.SplitMix as SplitMix
import qualified Pawl.Types.TapState as TapState
import qualified Pawl.Types.Terminal as Terminal
import qualified Pawl.Types.Zone as Zone
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
    let people = Map.fromList [(S.alice, Game.human (screen 300 plays) (const Nothing)), (S.bob, Game.human (screen 300 plays) (const Nothing))]
        shown = reverse (written (State.execState (Game.run [] people Hotseat.fresh (SplitMix.MkSplitMix 1) matchup) blank))
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
        human = Game.human (screen 2 (const (Just (Text.pack "1")))) (const Nothing)
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT twice (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.autoPass = False})) blank))
    Spec.assertEqWith s "once" (filter (Text.isInfixOf (Text.pack "reveals")) shown) [Text.pack "Player 2 reveals a face-down card."]

  Spec.it s "a seat passed for while facing the screen is shown its creature spell resolving" $ do
    gs <- started s registry
    lands <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Forest"]
    bears <- S.printingOf s registry "Grizzly Bears"
    let (board, _) = S.handOne bears (List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs lands)
        turn = GameState.turnNumber board
        seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 (castsOnce "Grizzly Bears")) (const Nothing))) Bot.bot
        run = Driver.drive [] seats 40 (pure . (> turn) . GameState.turnNumber) board
        (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank
        -- Since alice last answered: the auto payment ends her questions.
        unanswered = pending sc
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Grizzly Bears moves from the stack to the battlefield")) unanswered) ("shown the bear resolve: " <> show unanswered)
    Spec.assertEqWith s "as a line of its own, to a seat that never stopped looking" (filter (Text.isPrefixOf (Text.pack "Since you last looked")) unanswered) []
    Spec.assertBool s (Text.pack "Player 1 passes in their precombat main phase (no other actions)." `elem` unanswered) "passed for, in its main phase"
    Spec.assertEqWith s "into the next turn" (fmap ((> turn) . GameState.turnNumber) outcome) (Right True)

  Spec.it s "news read at a pass made for a seat the screen does not face waits for its next question, past the turn's end" $ do
    gs <- started s registry
    hand <- maybe (Spec.assertFailure s "no card in hand") pure (Maybe.listToMaybe (Game.Engine.zoneMembers Zone.Hand S.alice gs))
    let revealed = GameEvent.Revealed (Revealed.MkRevealed S.bob (ObjectId.MkObjectId 7) RevealCause.LeavingFaceDown S.emptyCharacteristics)
        decider = Decider.MkDecider S.alice
        witnessing = gs {GameState.events = Seq.singleton (LoggedEvent.MkLoggedEvent (EventGroup.MkEventGroup 0) revealed)}
        nextTurn = gs {GameState.events = Seq.empty, GameState.turnNumber = GameState.turnNumber gs + 1}
        passing = Answerer.unwrap human (Asked.MkAsked [] witnessing (Prompt.ChooseAction decider S.alice [Action.Pass]))
        acting = Answerer.unwrap human (Asked.MkAsked [] nextTurn (Prompt.ChooseAction decider S.alice [Action.Play hand Nothing, Action.Pass]))
        -- Enter at the hand-off, then Pass.
        human = Game.human (screen 2 (\sc -> Just (Text.pack (if typed sc == 0 then "" else "2")))) (const Nothing)
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT (passing >> acting) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Just S.bob})) blank))
        (facingBob, facingAlice) = break (Text.isPrefixOf (Text.pack "Pass to Player 1")) shown
        news = filter (Text.isPrefixOf (Text.pack "Since you last looked: "))
    Spec.assertEqWith s "not shown while the screen faces Player 2" (news facingBob) []
    Spec.assertEqWith s "shown at its next question, a turn later" (news facingAlice) [Text.pack "Since you last looked: Player 2 reveals a face-down card."]
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Player 1 passes in ")) facingBob) "passed for"

  Spec.it s "CR 514.1 a discard to hand size at cleanup is shown the other seat at its next question, a turn later" $ do
    gs <- started s registry
    giant <- S.printingOf s registry "Hill Giant"
    let board = snd (S.addHandCard giant S.alice gs)
        turn = GameState.turnNumber board
        person = Game.human (screen 200 discardsGiant) (const Nothing)
        seats = Driver.bySeat (Map.fromList [(S.alice, person), (S.bob, person)]) Bot.bot
        run = Driver.drive [] seats 200 (pure . (> turn + 1) . GameState.turnNumber) board
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank))
        discarding = Text.isPrefixOf (Text.pack "Choose 1 card to discard")
        -- Bob's first screen after the discard.
        facingBob = takeWhile (not . Text.isPrefixOf (Text.pack "Pass to Player 1")) (dropWhile (not . Text.isPrefixOf (Text.pack "Pass to Player 2")) (dropWhile (not . discarding) shown))
        news = filter (Text.isPrefixOf (Text.pack "Since you last looked: ")) facingBob
    Spec.assertBool s (any (Text.isInfixOf (Text.pack "Player 1 discards Hill Giant.")) news) ("shown the discard: " <> show news)
    Spec.assertBool s (not (any (Text.isInfixOf (Text.pack "Hill Giant is put into a graveyard")) news)) ("the discard's move, told once: " <> show news)
    Spec.assertBool s (any discarding shown) "Player 1 discarded at cleanup"

  Spec.it s "CR 113.7a Mindslaver's ability is named by its source at its target prompt and on the stack" $ do
    gs <- started s registry
    mindslaver <- S.printingOf s registry "Mindslaver"
    mountains <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Mountain", "Mountain"]
    let board = List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs (mindslaver : mountains)
        turn = GameState.turnNumber board
        seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 slavesBob) (const Nothing))) Bot.bot
        run = Driver.drive [] seats 200 (pure . (> turn) . GameState.turnNumber) board
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT run (SplitMix.MkSplitMix 1)) Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.autoPass = False})) blank))
        stacks = filter (Text.isPrefixOf (Text.pack "Stack, top first: "))
        stackLine = Text.pack "Stack, top first: Mindslaver's ability"
    -- Asked while Mindslaver is on the battlefield; the stack shown then and
    -- once its sacrifice has moved it, a witnessed move naming it.
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Choose 1 target for Mindslaver's ability ")) shown) "the target prompt names it"
    Spec.assertEqWith s "the stack names it, then once it is sacrificed" (Set.toList (Set.fromList (stacks shown)), take 1 (stacks (dropWhile (/= Text.pack "  Graveyard: Mindslaver") shown))) ([stackLine], [stackLine])
    Spec.assertEqWith s "no face-down card" (filter (Text.isInfixOf (Text.pack "face-down")) shown) []

  Spec.it s "CR 723.6 a seat controlled for its turn is still shown the rest of the turn before, and that turn, at its next question" $ do
    gs <- started s registry
    giant <- S.printingOf s registry "Hill Giant"
    mindslaver <- S.printingOf s registry "Mindslaver"
    mountains <- mapM (S.printingOf s registry) ["Mountain", "Mountain", "Mountain", "Mountain"]
    let board = snd (S.addHandCard giant S.alice (List.foldl' (\g p -> snd (S.addPermanent p S.alice g)) gs (mindslaver : mountains)))
        turn = GameState.turnNumber board
        person = Game.human (screen 400 slavesBob) (const Nothing)
        seats = Driver.bySeat (Map.fromList [(S.alice, person), (S.bob, person)]) Bot.bot
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
    Spec.assertEqWith s "blockers" (answering gs "2:1" (Prompt.DeclareBlockers bob S.bob [o5, o9] [o7])) (Right (Map.singleton o9 (Set.singleton o7)))
    Spec.assertEqWith s "targets" (answering gs "1" (Prompt.ChooseTargets alice S.alice o7 (Map.singleton slot (1, Set.fromList [Recipient.ToPlayer S.bob, Recipient.ToCreature o9])))) (Right (Map.singleton slot (Set.singleton (Recipient.ToCreature o9))))
    Spec.assertEqWith s "optional" (answering gs "2" (Prompt.ChooseOptional alice S.alice o7 (ModeIndex.MkModeIndex 0) (ClauseIndex.MkClauseIndex 0) mempty)) (Right OptionalDecision.Declines)
    Spec.assertEqWith s "x" (answering gs "3" (Prompt.ChooseX alice S.alice o7 Binding.variableX 1 5)) (Right 3)
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

  Spec.it s "a priority offering only passing and mana abilities is passed without asking or handing off" $ do
    (forest, gs) <- withForest s registry
    hand <- maybe (Spec.assertFailure s "no card in hand") pure (Maybe.listToMaybe (Game.Engine.zoneMembers Zone.Hand S.alice gs))
    let decider = Decider.MkDecider S.alice
        manaOnly = Prompt.ChooseAction decider S.alice [Action.ActivateManaAbility forest, Action.Pass]
        facingBob = Hotseat.fresh {Hotseat.facing = Just S.bob}
        facingAlice = Hotseat.fresh {Hotseat.facing = Just S.alice}
        upkeep = gs {GameState.phase = Phase.Beginning BeginningStep.Upkeep, GameState.activePlayer = S.bob}
    Spec.assertEqWith s "passed for, in the other seat's upkeep" (asking facingBob [] upkeep manaOnly) (Right Action.Pass, [Text.pack "Player 1 passes in Player 2's upkeep (no other actions)."])
    let menu (outcome, shown) = (outcome, any menuHeading shown)
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
    (lands, resolved, tapped, shown) <- autoCast s registry "Grizzly Bears" ["Mountain", "Mountain", "Forest"]
    Spec.assertEqWith s "the bear resolved" resolved True
    Spec.assertEqWith s "the Forest and one Mountain tapped" (fmap (`elem` tapped) lands) [True, False, True]
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Paying {1}{G}.")) shown) "asked with the cost"

  -- The Plateau makes red ahead of white, so taking its first yield fails.
  Spec.it s "auto pays through a dual land, taking the color still owed" $ do
    (lands, resolved, tapped, shown) <- autoCast s registry "Savannah Lions" ["Taiga", "Plateau"]
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

  Spec.it s "a seat's battlefield is grouped lands, creatures, then the rest, each by mana value and name" $ do
    printings <- mapM (S.printingOf s registry) ["Lizard Warrior", "Hill Giant", "Mountain", "Grizzly Bears", "Bad Moon", "Forest", "Raging Goblin", "Plains"]
    let (gs, placed) = List.mapAccumL (\g p -> let (oid, g') = S.addPermanent p S.alice g in (g', oid)) (Setup.emptyGame S.bothPlayers) printings
        tapped = case drop 2 placed of
          mountain : _ -> gs {GameState.objects = Map.adjust (\o -> o {Object.tapped = TapState.Tapped}) mountain (GameState.objects gs)}
          [] -> gs
        shown = filter (Text.isPrefixOf (Text.pack "  ")) (Render.board (PlayerView.viewFor S.alice tapped))
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
    Spec.assertEqWith s "by name" (cardLines byName) ([Text.pack "Raging Goblin 2/2 (1 damage, 1 counter)", Text.pack "Raging Goblin {R}", Text.pack "Creature \8212 Berserker Goblin", Text.pack "2/2", Text.pack "Counters: 1 +1/+1"] <> Text.lines text)
    Spec.assertBool s (not (null (Text.lines text))) "Raging Goblin has Oracle text"
    Spec.assertBool s (Text.pack "Type card and a number from a list, or a card's name, to read that card." `elem` byName) "the first screen says how"
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

  Spec.it s "card shows nothing of a card in another seat's hand" $ do
    piker <- S.printingOf s registry "Goblin Piker"
    lookUp <- cardsNamed s registry ["Goblin Piker"]
    let (_, gs) = S.addObjectIn Zone.Hand piker S.bob (Setup.emptyGame S.bothPlayers)
        priority pid = Prompt.ChooseAction (Decider.MkDecider pid) pid [Action.Pass]
        seenBy pid = cardLines (readout lookUp gs ["card Goblin Piker", "1"] (priority pid))
    Spec.assertEqWith s "alice" (seenBy S.alice) [Text.pack "No card you can see is named Goblin Piker."]
    Spec.assertEqWith s "bob" (take 2 (seenBy S.bob)) [Text.pack "Goblin Piker 2/1", Text.pack "Goblin Piker {1}{R}"]

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

-- Alice at the terminal, the bot as bob.
against :: (Screen -> Maybe Text.Text) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> (Either Text.Text (Result.Result, GameState.GameState), [Text.Text])
against typist matchup =
  let seats = Map.fromList [(S.alice, Game.human (screen 3000 typist) (const Nothing)), (S.bob, Bot.bot)]
      (outcome, sc) = State.runState (Game.run [] seats Hotseat.fresh {Hotseat.facing = Just S.alice} (SplitMix.MkSplitMix 1) matchup) blank
   in (outcome, reverse (written sc))

-- Since the last line typed.
pending :: Screen -> [Text.Text]
pending = reverse . takeWhile (not . Text.isPrefixOf (Text.pack "> ")) . written

typedYet :: String -> Screen -> Bool
typedYet line = elem (Text.pack ("> " <> line)) . written

-- Plays a land or casts a spell when it can, attacks with its first creature,
-- never blocks, pays with the first source, and keeps its hand.
plays :: Screen -> Maybe Text.Text
plays sc
  | any (Text.isPrefixOf (Text.pack "Pass to ")) shown = Just Text.empty
  | any (Text.isPrefixOf (Text.pack "Type the answer as JSON")) shown = Nothing
  | Just n <- Maybe.listToMaybe (Maybe.mapMaybe wanted shown) = Just (Text.unwords (fmap (Text.pack . show) [1 .. n]))
  | any (Text.isPrefixOf (Text.pack "Type blocker:attacker")) shown = Just Text.empty
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
      (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap (Game.human terminal (const Nothing)) (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) hotseat)) blank
   in (outcome, reverse (written sc))

-- Alice casting a creature spell with auto from a game after setup and the
-- named lands: the lands, whether it resolved, which lands it tapped, and
-- what the screen showed.
autoCast :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> String -> [String] -> m ([ObjectId.ObjectId], Bool, [ObjectId.ObjectId], [Text.Text])
autoCast s registry spell names = do
  gs <- started s registry
  printings <- mapM (S.printingOf s registry) names
  card <- S.printingOf s registry spell
  let place (placed, g) printing = let (oid, g') = S.addPermanent printing S.alice g in (placed <> [oid], g')
      (lands, withLands) = List.foldl' place ([], gs) printings
      board = snd (S.addHandCard card S.alice withLands)
      bears = S.countOnBattlefieldByName (CardName.MkCardName (Text.pack spell)) S.alice
      seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 (castsOnce spell)) (const Nothing))) Bot.bot
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

-- Casts the first of the spell it is offered, has auto pay for it, and
-- passes otherwise.
castsOnce :: String -> Screen -> Maybe Text.Text
castsOnce spell sc
  | any (Text.isPrefixOf (Text.pack "Paying ")) shown = Just (Text.pack "auto")
  | any menuHeading shown =
      let options = [(n, rest) | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], Text.all (`elem` ['0' .. '9']) n, not (Text.null n)]
          cast = [n | not (typedYet "auto" sc), (n, rest) <- options, rest == Text.pack (". Cast " <> spell)]
       in Maybe.listToMaybe (cast <> [n | (n, rest) <- options, rest == Text.pack ". Pass"])
  | otherwise = plays sc
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
  -- Tap, then sacrifice: the protocol offers nothing for this prompt (#5225).
  | Text.pack "order cost components:" `elem` shown = Just (Text.pack "[0,1]")
  | any menuHeading shown, Just n <- numberOf ". Activate an ability of Mindslaver" = Just n
  | any (Text.isPrefixOf (Text.pack "Choose 1 card to discard")) shown = Monad.mplus (numberOf ". Hill Giant") (Just (Text.pack "1"))
  | otherwise = discardsGiant sc
  where
    shown = pending sc
    numberOf wanted = Maybe.listToMaybe [n | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], not (Text.null n), Text.all (`elem` ['0' .. '9']) n, rest == Text.pack wanted]

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
    (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap (Game.human (screen 1 (const (Just (Text.pack line)))) (const Nothing)) (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Driver.deciderOf prompt}))
    blank

-- What one prompt showed its seat, the lines typed one after another.
readout :: (CardName.CardName -> Maybe Card.Card) -> GameState.GameState -> [String] -> Prompt.Prompt r -> [Text.Text]
readout lookUp gs typing prompt =
  let typist sc = fmap Text.pack (Maybe.listToMaybe (List.genericDrop (typed sc) typing))
      human = Game.human (screen (Natural.length typing) typist) lookUp
   in reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap human (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Driver.deciderOf prompt, Hotseat.autoPass = False})) blank))

-- What the first "card" line typed showed.
cardLines :: [Text.Text] -> [Text.Text]
cardLines = takeWhile (not . Text.isPrefixOf (Text.pack "> ")) . drop 1 . dropWhile (not . Text.isPrefixOf (Text.pack "> card"))

-- The card data for these cards, by each face's name.
cardsNamed :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> [String] -> m (CardName.CardName -> Maybe Card.Card)
cardsNamed s registry names = do
  cards <- mapM (S.cardOf s registry) names
  let byName = Map.fromList [(Face.name f, card) | card <- cards, f <- Foldable.toList (Card.faces card)]
  pure (`Map.lookup` byName)

-- A one-faced card's printed Oracle text.
oracleOf :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> String -> m Text.Text
oracleOf s registry name = fmap (foldMap (Maybe.fromMaybe Text.empty . Face.oracleText) . Card.faces) (S.cardOf s registry name)

-- A game after setup: alice red, bob green, hands drawn.
started :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m GameState.GameState
started s registry = do
  matchup <- BotSpec.bears s registry
  pure (snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup)))
