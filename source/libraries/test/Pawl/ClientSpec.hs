{-# LANGUAGE GADTs #-}

-- Covers Pawl.Play.Client, Pawl.Play.Render and Pawl.Play.Game: a person at
-- a terminal playing through request lines, against the bot or another
-- person on the same screen.
module Pawl.ClientSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.BotSpec as BotSpec
import qualified Pawl.Engine.Driver as Driver
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Game as Game
import qualified Pawl.Registry as Registry
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Action as Action
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.ClauseIndex as ClauseIndex
import qualified Pawl.Types.Decider as Decider
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.EventGroup as EventGroup
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.ModeIndex as ModeIndex
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
import qualified Pawl.Types.Terminal as Terminal
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
        shown = reverse (written (State.execState (Except.runExceptT (State.evalStateT (State.evalStateT twice (SplitMix.MkSplitMix 0)) Hotseat.fresh {Hotseat.facing = Just S.alice})) blank))
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
    Spec.assertEqWith s "x" (answering gs "3" (Prompt.ChooseX alice S.alice o7 1 5)) (Right 3)
    Spec.assertEqWith s "mana source" (answering gs "0" (Prompt.ChooseManaSource alice S.alice (o7 NonEmpty.:| [o9]))) (Right Nothing)

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
