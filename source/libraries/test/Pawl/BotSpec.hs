{-# LANGUAGE GADTs #-}

-- Covers Pawl.Play.Chance and Pawl.Play.Bot: chance answered from a seeded
-- generator, and a seat answered at random among what its prompts offer.
module Pawl.BotSpec where

import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Word as Word
import qualified Pawl.Engine.Driver as Driver
import qualified Pawl.Engine.Engine as Engine
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Engine.Replay as Replay
import qualified Pawl.Engine.Resolve.Effect as Resolve
import qualified Pawl.Engine.Setup as Setup
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Chance as Chance
import qualified Pawl.Registry as Registry
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Observer as Observer
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.SplitMix as SplitMix
import qualified Pawl.Types.Zone as Zone

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

-- One seated answer: whether the prompt offered it, and whether it declared
-- an attack.
data Answered = MkAnswered {within :: Bool, attacked :: Bool}

played :: Word.Word64 -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> ((Result.Result, GameState.GameState), [Answered])
played seed matchup =
  let seats :: Map.Map PlayerId.PlayerId (Answerer.Answerer (State.StateT SplitMix.SplitMix (State.State [Answered])))
      seats = Map.fromList [(S.alice, Bot.bot), (S.bob, Bot.bot)]
   in State.runState (State.evalStateT (Driver.match [watching] (Driver.bySeat seats Chance.chance) GameSettings.plain matchup) (SplitMix.MkSplitMix seed)) []

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

setUp :: Answerer.Answerer (State.State SplitMix.SplitMix) -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> State.State SplitMix.SplitMix GameState.GameState
setUp answerer matchup =
  fmap snd (Engine.runGameAsked (Answerer.unwrap answerer) (Setup.gameWith GameSettings.plain (fmap fst matchup)) (Setup.newGame (Resolve.performHandAction Engine.playSubgame) matchup))

-- Twelve Grizzly Bears and eight Forests apiece: short enough to deck out.
bears :: (Monad m) => Spec.Spec m n -> Registry.Registry m -> m (NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck))
bears s registry = do
  bear <- S.printingOf s registry "Grizzly Bears"
  forest <- S.printingOf s registry "Forest"
  let deck = Deck.fromCards (Map.fromList [(bear, 12), (forest, 8)])
  pure ((S.alice, deck) NonEmpty.:| [(S.bob, deck)])
