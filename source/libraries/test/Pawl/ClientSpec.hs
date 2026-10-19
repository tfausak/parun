{-# LANGUAGE GADTs #-}

-- Covers Pawl.Play.Client, Pawl.Play.Render and Pawl.Play.Game: a person at
-- a terminal playing through request lines, against the bot or another
-- person on the same screen.
module Pawl.ClientSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Either as Either
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
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.ManaSpec as ManaSpec
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Game as Game
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.ClauseIndex as ClauseIndex
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.EventGroup as EventGroup
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
    Spec.assertBool s (any (\l -> Text.isPrefixOf (Text.pack "  Battlefield: ") l && Text.isInfixOf (Text.pack "Grizzly Bears 2/2") l) shown) "cast"

  Spec.it s "a seat that types concede loses at its next priority" $ do
    matchup <- BotSpec.bears s registry
    let conceding sc = if not (typedYet "concede" sc) && saw "Choose an action:" sc then Just (Text.pack "concede") else plays sc
    Spec.assertEq s (fmap fst (fst (against conceding matchup))) (Right (Result.Won S.bob))

  Spec.it s "an option that is not offered is asked again before reaching the engine" $ do
    matchup <- BotSpec.bears s registry
    let straying sc = if not (typedYet "99" sc) && saw "Choose an action:" sc then Just (Text.pack "99") else plays sc
        shown = snd (against straying matchup)
        after = drop 1 (dropWhile (/= Text.pack "> 99") shown)
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Type one number from 1 to")) (take 1 after)) "asked again"
    Spec.assertBool s (Text.pack "Choose an action:" `elem` after) "played on"

  Spec.it s "a change of seat clears the screen and waits before showing the next seat" $ do
    matchup <- BotSpec.bears s registry
    let people = Map.fromList [(S.alice, Game.human (screen 300 plays)), (S.bob, Game.human (screen 300 plays))]
        shown = reverse (written (State.execState (Game.run [] people Hotseat.fresh (SplitMix.MkSplitMix 1) matchup) blank))
        handOffs = [i | (i, l) <- zip [0 :: Int ..] shown, Text.isPrefixOf (Text.pack "Pass to ") l]
        at i = Maybe.listToMaybe (drop i shown)
        -- The last hand-off may be cut short by the end of input.
        cleared i = at (i - 1) == Just (Text.pack "<clear>") && (at (i + 2) == Just (Text.pack "<clear>") || at (i + 1) == Just (Text.pack "<eof>"))
    Spec.assertBool s (any (Text.isPrefixOf (Text.pack "Pass to Player 1")) shown && any (Text.isPrefixOf (Text.pack "Pass to Player 2")) shown) "both seats"
    Spec.assertBool s (all cleared handOffs) "cleared"
    Spec.assertEqWith s "seen by the seat passed to" (mismatches shown) []

  Spec.it s "a seat is shown what it witnessed once" $ do
    gs <- started s registry
    let revealed = GameEvent.Revealed (Revealed.MkRevealed S.bob (ObjectId.MkObjectId 7) RevealCause.LeavingFaceDown S.emptyCharacteristics)
        witnessing = gs {GameState.events = Seq.singleton (LoggedEvent.MkLoggedEvent (EventGroup.MkEventGroup 0) revealed)}
        acting = Asked.MkAsked [] witnessing (Prompt.ChooseAction (Decider.MkDecider S.alice) S.alice [Action.Pass])
        twice = Answerer.unwrap human acting >> Answerer.unwrap human acting
        human = Game.human (screen 2 (const (Just (Text.pack "1"))))
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT twice (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Just S.alice, Hotseat.autoPass = False})) blank))
    Spec.assertEqWith s "once" (filter (Text.isPrefixOf (Text.pack "Since you last looked: ")) shown) [Text.pack "Since you last looked: Player 2 reveals a face-down card."]

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
    Spec.assertEqWith s "mana source" (answering gs "0" (Prompt.ChooseManaSource alice S.alice (ManaCost.MkManaCost [ManaSymbol.Generic 1]) (o7 NonEmpty.:| [o9]))) (Right Nothing)

  Spec.it s "a priority offering only passing and mana abilities is passed without asking or handing off" $ do
    (forest, gs) <- withForest s registry
    hand <- maybe (Spec.assertFailure s "no card in hand") pure (Maybe.listToMaybe (Game.Engine.zoneMembers Zone.Hand S.alice gs))
    let decider = Decider.MkDecider S.alice
        manaOnly = Prompt.ChooseAction decider S.alice [Action.ActivateManaAbility forest, Action.Pass]
        facingBob = Hotseat.fresh {Hotseat.facing = Just S.bob}
        facingAlice = Hotseat.fresh {Hotseat.facing = Just S.alice}
    Spec.assertEqWith s "passed for" (asking facingBob [] gs manaOnly) (Right Action.Pass, [Text.pack "Player 1 passes (no other actions)."])
    let menu (outcome, shown) = (outcome, Text.pack "Choose an action:" `elem` shown)
    Spec.assertEqWith s "asked when turned off" (menu (asking facingAlice {Hotseat.autoPass = False} [] gs manaOnly)) (Left (Text.pack "end of input"), True)
    Spec.assertEqWith s "asked with a land to play" (menu (asking facingAlice [] gs (Prompt.ChooseAction decider S.alice [Action.Play hand Nothing, Action.Pass]))) (Left (Text.pack "end of input"), True)

  Spec.it s "a person against the bot is never shown an action menu of passing and mana abilities alone" $ do
    matchup <- BotSpec.bears s registry
    let (outcome, shown) = against plays matchup
        menus = actionMenus shown
    Spec.assertBool s (either (const False) (const True) outcome) ("finished: " <> show (fmap fst outcome))
    Spec.assertEqWith s "menus of passing and mana abilities" (filter (all (\o -> o == Text.pack "Pass" || Text.isPrefixOf (Text.pack "Activate a mana ability of ") o)) menus) []
    Spec.assertBool s (Text.pack "Player 1 passes (no other actions)." `elem` shown) "passed for"

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
    Spec.assertEqWith
      s
      "floats nothing once covered"
      (asking facing {Hotseat.paying = Map.singleton S.alice Set.empty} [] board (Prompt.ChooseExtraManaSource decider S.alice (m NonEmpty.:| [])))
      (Right Nothing, [])

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
  let seats = Map.fromList [(S.alice, Game.human (screen 3000 typist)), (S.bob, Bot.bot)]
      (outcome, sc) = State.runState (Game.run [] seats Hotseat.fresh {Hotseat.facing = Just S.alice} (SplitMix.MkSplitMix 1) matchup) blank
   in (outcome, reverse (written sc))

-- Since the last line typed.
pending :: Screen -> [Text.Text]
pending = reverse . takeWhile (not . Text.isPrefixOf (Text.pack "> ")) . written

saw :: String -> Screen -> Bool
saw line = elem (Text.pack line) . pending

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
  | Text.pack "Choose an action:" `elem` shown =
      let options = Maybe.mapMaybe option shown
          pick = List.find (\(_, t) -> any (`Text.isPrefixOf` t) [Text.pack "Play ", Text.pack "Cast "]) options
       in fmap fst (Monad.mplus pick (List.find ((== Text.pack "Pass") . snd) options))
  | Just least <- Maybe.listToMaybe (Maybe.mapMaybe leastX shown) = Just least
  | any (Text.isPrefixOf (Text.pack "The cost is covered.")) shown = Just (Text.pack "0")
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
      (outcome, sc) = State.runState (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap (Game.human terminal) (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) hotseat)) blank
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
      seats = Driver.bySeat (Map.singleton S.alice (Game.human (screen 200 (castsOnce spell)))) Bot.bot
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
  | Text.pack "Choose an action:" `elem` shown =
      let options = [(n, rest) | line <- shown, (n, rest) <- [Text.breakOn (Text.pack ". ") (Text.strip line)], Text.all (`elem` ['0' .. '9']) n, not (Text.null n)]
          cast = [n | not (typedYet "auto" sc), (n, rest) <- options, rest == Text.pack (". Cast " <> spell)]
       in Maybe.listToMaybe (cast <> [n | (n, rest) <- options, rest == Text.pack ". Pass"])
  | otherwise = plays sc
  where
    shown = pending sc

-- Each action menu shown, by its options.
actionMenus :: [Text.Text] -> [[Text.Text]]
actionMenus shown = case dropWhile (/= Text.pack "Choose an action:") shown of
  [] -> []
  _ : rest ->
    let (menu, after) = span (Text.isPrefixOf (Text.pack "  ")) rest
     in fmap (Text.drop 2 . snd . Text.breakOn (Text.pack ". ")) menu : actionMenus after

-- One prompt answered by alice typing one line.
answering :: GameState.GameState -> String -> Prompt.Prompt r -> Either Text.Text r
answering gs line prompt =
  State.evalState
    (Except.runExceptT (State.evalStateT (State.evalStateT (Answerer.unwrap (Game.human (screen 1 (const (Just (Text.pack line))))) (Asked.MkAsked [] gs prompt)) (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Driver.deciderOf prompt}))
    blank

-- A game after setup: alice red, bob green, hands drawn.
started :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m GameState.GameState
started s registry = do
  matchup <- BotSpec.bears s registry
  pure (snd (Engine.runGamePure S.castAnswer (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup)))
