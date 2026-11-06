{-# LANGUAGE GADTs #-}

-- Covers Parun.Play.Chance and Parun.Play.Bot: chance answered from a seeded
-- generator, and a seat answered at random among what its prompts offer.
module Parun.BotSpec where

import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Word as Word
import Numeric.Natural (Natural)
import qualified Parun.Engine.Decide as Decide
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Monarch as Monarch
import qualified Parun.Engine.PlayerView as PlayerView
import qualified Parun.Engine.Replay as Replay
import qualified Parun.Engine.Resolve.Effect as Resolve
import qualified Parun.Engine.Setup as Setup
import qualified Parun.ManaSourceSpec as ManaSourceSpec
import qualified Parun.Play.Bot as Bot
import qualified Parun.Play.Chance as Chance
import qualified Parun.Registry as Registry
import qualified Parun.ReplaySpec as ReplaySpec
import qualified Parun.Scenario as Scenario
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.Dividing as Dividing
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.GuessAnswer as GuessAnswer
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.NumberFloor as NumberFloor
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.PayOffer as PayOffer
import qualified Parun.Types.PaymentDecision as PaymentDecision
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Result as Result
import qualified Parun.Types.SplitMix as SplitMix
import qualified Parun.Types.TriggerEntry as TriggerEntry
import qualified Parun.Types.TriggerSource as TriggerSource
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Bot" $ do
  Spec.it s "chance shuffles each library from its seed" $ do
    matchup <- bears s registry
    let libraries gs = fmap (\pid -> Game.zoneMembers Zone.Library pid gs) [S.alice, S.bob]
        seeded seed = libraries (State.evalState (setUp Chance.chance matchup) (SplitMix.MkSplitMix seed))
        unshuffled = libraries (State.evalState (setUp (Answerer.MkAnswerer (pure . Replay.defaultAnswer . Asked.prompt)) matchup) (SplitMix.MkSplitMix 0))
    Spec.assertBool s (seeded 1 /= unshuffled) "shuffled"
    Spec.assertEq s (seeded 1) (seeded 1)
    Spec.assertBool s (seeded 1 /= seeded 2) "by seed"

  Spec.it s "two bots finish a game, answering only what each prompt offers" $ do
    matchup <- bears s registry
    let ((result, gs), answers) = played 1 matchup
    Spec.assertBool s (GameState.result gs == Just result) "finished"
    Spec.assertBool s (all within answers) "within offer"
    Spec.assertBool s (any attacked answers) "attacked"
    Spec.assertEq s (fst (played 1 matchup)) (result, gs)

  Spec.it s "picks among every mana a source's ability can produce" $ do
    let options = ReplaySpec.oneMana Color.Red NonEmpty.:| [ReplaySpec.oneMana Color.Green, ReplaySpec.oneMana Color.Blue]
    Spec.assertEqWith s "yields" (drawn (Prompt.ChooseManaYield decider S.alice oid options)) (Set.fromList (NonEmpty.toList options))

  Spec.it s "puts triggers on the stack in every order" $ do
    let entries =
          [ TriggerEntry.MkTriggerEntry (TriggerSource.OfObject oid) Monarch.crownSteal,
            TriggerEntry.MkTriggerEntry TriggerSource.Sourceless Monarch.endStepDraw,
            TriggerEntry.MkTriggerEntry (TriggerSource.OfObject (ObjectId.MkObjectId 8)) Monarch.crownSteal
          ]
    Spec.assertEqWith s "orders" (drawn (Prompt.OrderTriggers decider S.alice entries)) (Set.fromList (List.permutations [0, 1, 2]))

  -- CR 510.1c / 702.19b: a trampler with power 4 blocked by creatures two and
  -- one short of lethal. Fifteen ways to divide 4 among three; the six legal
  -- ones keep the player at nothing until both blockers have lethal.
  Spec.it s "divides combat damage every legal way and no other" $ do
    let first = Recipient.ToCreature (ObjectId.MkObjectId 8)
        second = Recipient.ToCreature (ObjectId.MkObjectId 9)
        player = Recipient.ToPlayer S.bob
        thresholds :: Map.Map Recipient.Recipient Natural
        thresholds = Map.fromList [(first, 2), (second, 1), (player, 0)]
        legal :: [Map.Map Recipient.Recipient Natural]
        legal =
          fmap
            (Map.filter (> 0) . Map.fromList . zip [first, second, player])
            [[4, 0, 0], [3, 1, 0], [2, 2, 0], [1, 3, 0], [0, 4, 0], [2, 1, 1]]
    Spec.assertEqWith s "divisions" (drawn (Prompt.AssignCombatDamage decider S.alice oid thresholds 4)) (Set.fromList legal)

  -- CR 601.2d: 4 among three targets, each at least 1, is three ways; CR
  -- 115.7f's fixed parts 1 and 3 between two targets are two.
  Spec.it s "divides among targets every legal way and no other" $ do
    let first = Recipient.ToCreature (ObjectId.MkObjectId 8)
        second = Recipient.ToCreature (ObjectId.MkObjectId 9)
        player = Recipient.ToPlayer S.bob
        ways :: [[Natural]] -> [Recipient.Recipient] -> Set.Set (Map.Map Recipient.Recipient Natural)
        ways parts targets = Set.fromList (fmap (Map.fromList . zip targets) parts)
    Spec.assertEqWith s "totals" (drawn (Prompt.ChooseDivision decider S.alice oid (Dividing.Total 4) (first NonEmpty.:| [second, player]))) (ways [[2, 1, 1], [1, 2, 1], [1, 1, 2]] [first, second, player])
    Spec.assertEqWith s "parts" (drawn (Prompt.ChooseDivision decider S.alice oid (Dividing.Parts (1 NonEmpty.:| [3])) (first NonEmpty.:| [second]))) (ways [[1, 3], [3, 1]] [first, second])

  Spec.it s "pays or declines what a resolving spell offers" $ do
    let offer = PayOffer.AtClause (ModeIndex.MkModeIndex 0) (ClauseIndex.MkClauseIndex 0)
        cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 3]), Cost.components = []}
    Spec.assertEqWith s "decisions" (drawn (Prompt.ChooseToPay decider S.alice oid offer cost Seq.empty)) (Set.fromList [PaymentDecision.Declines, PaymentDecision.Pays])

  Spec.it s "taps another source or pays now once the cost is covered" $ do
    let sources = ObjectId.MkObjectId 8 NonEmpty.:| [ObjectId.MkObjectId 9]
    Spec.assertEqWith s "sources" (drawn (Prompt.ChooseExtraManaSource decider S.alice sources)) (Set.fromList (Nothing : fmap Just (NonEmpty.toList sources)))

  Spec.it s "spends any unit the pool offers" $ do
    let units = ManaSourceSpec.plainColor Color.Red NonEmpty.:| [ManaSourceSpec.plainColor Color.Green]
    Spec.assertEqWith s "units" (drawn (Prompt.ChooseManaToSpend decider S.alice units)) (Set.fromList (NonEmpty.toList units))

  -- CR 701.23b: a search for cards of a stated quality may find fewer, so
  -- every group of at most two of the three matches is an answer.
  Spec.it s "finds any group of at most so many matching cards" $ do
    let cards = fmap ObjectId.MkObjectId [8, 9, 10]
    Spec.assertEqWith s "groups" (Set.map List.sort (drawn (Prompt.Search decider S.alice cards 2))) (Set.fromList (filter ((<= 2) . length) (List.subsequences cards)))

  -- CR 608.2d: Imperial Edict's "a creature they control" is any of them.
  Spec.it s "chooses any matching permanent" $ do
    let candidates = ObjectId.MkObjectId 8 NonEmpty.:| [ObjectId.MkObjectId 9, ObjectId.MkObjectId 10]
    Spec.assertEqWith s "permanents" (drawn (Prompt.ChoosePermanent decider S.alice oid candidates Seq.empty)) (Set.fromList (NonEmpty.toList candidates))

  -- CR 608.2d: Coercion's "choose a card from it" is any of them.
  Spec.it s "chooses any card from among the group" $ do
    let candidates = ObjectId.MkObjectId 8 NonEmpty.:| [ObjectId.MkObjectId 9, ObjectId.MkObjectId 10]
    Spec.assertEqWith s "cards" (drawn (Prompt.ChooseCardFromAmong decider S.alice oid candidates)) (Set.fromList (NonEmpty.toList candidates))

  -- CR 701.21a: Wildfire's "sacrifices four lands" from five is any four.
  Spec.it s "sacrifices any group of the count" $ do
    let candidates = fmap ObjectId.MkObjectId [8 .. 12]
    Spec.assertEqWith s "groups" (drawn (Prompt.ChooseSacrifices decider S.alice oid candidates 4 Seq.empty)) (Set.fromList (fmap Set.fromList (filter ((== 4) . length) (List.subsequences candidates))))

  Spec.it s "guesses either way" $ do
    Spec.assertEqWith s "guesses" (drawn (Prompt.ChooseGuess decider S.alice oid (Filter.And []))) (Set.fromList [GuessAnswer.Holds, GuessAnswer.DoesNotHold])

  -- CR 107.1c: a bounded number is any from its floor to its bound; an
  -- unbounded bid tops the high bid by one or declines.
  Spec.it s "chooses any number in range and tops a bid by one" $ do
    Spec.assertEqWith s "bounded" (drawn (Prompt.ChooseNumber decider S.alice oid 1 NumberFloor.Least (Just 4))) (Set.fromList [1 .. 4])
    Spec.assertEqWith s "bid" (drawn (Prompt.ChooseNumber decider S.alice oid 3 NumberFloor.HighBid Nothing)) (Set.fromList [3, 4])

-- Every answer the bot gives the prompt over many seeds.
drawn :: (Ord r) => Prompt.Prompt r -> Set.Set r
drawn prompt = Set.fromList (fmap (State.evalState (Answerer.unwrap Bot.bot (Asked.mapGames (PlayerView.viewFor S.alice) (Asked.MkAsked [] (Setup.emptyGame S.bothPlayers) prompt))) . SplitMix.MkSplitMix) [1 .. 256])

decider :: Decider.Decider
decider = Decide.deciderFor S.alice (Setup.emptyGame S.bothPlayers)

oid :: ObjectId.ObjectId
oid = ObjectId.MkObjectId 7

-- One seated answer: whether the prompt offered it, and whether it declared
-- an attack.
data Answered = MkAnswered {within :: Bool, attacked :: Bool}

played :: Word.Word64 -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> ((Result.Result, GameState.GameState), [Answered])
played seed matchup =
  let seats :: Map.Map PlayerId.PlayerId (Answerer.Answerer (Asked.Asked GameState.GameState) (State.StateT SplitMix.SplitMix (State.State [Answered])))
      seats = Map.fromList [(S.alice, Driver.seated Bot.bot Chance.chance), (S.bob, Driver.seated Bot.bot Chance.chance)]
   in State.runState (State.evalStateT (Driver.match [watching] (Driver.bySeat seats Chance.chance) GameSettings.plain Map.empty matchup) (SplitMix.MkSplitMix seed)) []

watching :: Observer.Observer (State.StateT SplitMix.SplitMix (State.State [Answered]))
watching =
  Observer.MkObserver
    { Observer.before = \_ -> pure (),
      Observer.after = \asked answer ->
        let prompt = Asked.prompt asked
         in case Driver.deciderOf prompt of
              Nothing -> pure ()
              Just _ -> Trans.lift (State.modify' (<> [MkAnswered (Scenario.withinOffer prompt answer) (declares prompt answer)]))
    }

declares :: Prompt.Prompt r -> r -> Bool
declares prompt answer = case prompt of
  Prompt.DeclareAttackers {} -> not (null (answer :: [ObjectId.ObjectId]))
  _ -> False

setUp :: Answerer.Answerer (Asked.Asked GameState.GameState) (State.State SplitMix.SplitMix) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> State.State SplitMix.SplitMix GameState.GameState
setUp answerer matchup =
  fmap snd (Engine.runGameAsked (Answerer.unwrap answerer) (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup))

-- Twelve Grizzly Bears and eight Forests apiece: short enough to deck out.
bears :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck))
bears s registry = do
  bear <- S.printingOf s registry "Grizzly Bears"
  forest <- S.printingOf s registry "Forest"
  let deck = Deck.fromCards (Map.fromList [(bear, 12), (forest, 8)])
  pure ((S.alice, deck) NonEmpty.:| [(S.bob, deck)])
