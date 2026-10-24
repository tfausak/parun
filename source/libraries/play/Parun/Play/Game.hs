-- | A whole game: each seat answered by its own answerer (a person at the
-- terminal, a program over lines, or the random bot), chance by the
-- generator.
module Parun.Play.Game where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Parun.Play.Bot as Bot
import qualified Parun.Play.Chance as Chance
import qualified Parun.Play.Client as Client
import qualified Parun.Play.Protocol as Protocol
import qualified Parun.Play.SplitMix as SplitMix.Play
import qualified Parun.Types.Answerer as Answerer
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Hotseat as Hotseat
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.PlayOptions as PlayOptions
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Result as Result
import qualified Parun.Types.SplitMix as SplitMix
import qualified Parun.Types.Terminal as Terminal

-- | The generator over the client's monad.
type Play m = State.StateT SplitMix.SplitMix (Client.Client m)

-- | A person at the terminal, reading cards' printed text from the card data.
human :: (Monad m) => Terminal.Terminal m -> (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> Answerer.Answerer (Play m)
human terminal lookUp = Protocol.over (Trans.lift . Client.respond terminal lookUp) Chance.chance

-- | A program speaking the protocol: each request line out, its reply line
-- back, Nothing at the end of input.
wired :: (Monad m) => (Text.Text -> m (Maybe Text.Text)) -> Answerer.Answerer (Play m)
wired exchange = Protocol.over (\line -> Trans.lift (Client.lift2 (exchange line) >>= maybe (Client.stop (Text.pack "end of input")) pure)) Chance.chance

-- | A plain two-player game, from setup to its result; the head of the
-- matchup plays first. Left is why play stopped before the end.
run :: (Monad m) => [Observer.Observer (Play m)] -> Map.Map PlayerId.PlayerId (Answerer.Answerer (Play m)) -> Hotseat.Hotseat -> SplitMix.SplitMix -> NonEmpty.NonEmpty (PlayerId.PlayerId, Deck.Deck) -> m (Either Text.Text (Result.Result, GameState.GameState))
run observers seats hotseat generator matchup =
  Except.runExceptT (State.evalStateT (State.evalStateT (Driver.match observers (Driver.bySeat seats Chance.chance) GameSettings.plain matchup) generator) hotseat)

-- | Something of the base monad's, from inside a game.
underneath :: (Monad m) => m a -> Play m a
underneath = Trans.lift . Client.lift2

-- | CR 103.1: the seat that plays first. `--first` names it; otherwise a seat
-- drawn from the generator chooses whether to play first or draw, the bot
-- through 'Bot.playsFirst' and any other seat by `ask`, which is Nothing at
-- the end of input. Each step is told through `tell`.
starter :: (Monad m) => (Text.Text -> m ()) -> (Natural -> m (Maybe Bool)) -> PlayOptions.PlayOptions -> State.StateT SplitMix.SplitMix m (Maybe Natural)
starter tell ask options = case PlayOptions.first options of
  Just seat -> pure (Just seat)
  Nothing -> do
    chooser <- SplitMix.Play.pick (1 NonEmpty.:| [2])
    Trans.lift (tell (Text.pack ("Seat " <> show chooser <> " was picked at random to choose who plays first.")))
    plays <-
      if Set.member chooser (PlayOptions.bots options)
        then fmap Just Bot.playsFirst
        else Trans.lift (ask chooser)
    Monad.forM plays $ \chooses -> do
      let seat = if chooses == (chooser == 1) then 1 else 2 :: Natural
      Trans.lift (tell (Text.pack ("Seat " <> show seat <> " plays first.")))
      pure seat

-- | Whether this seat's person plays first rather than draws, asked until
-- they say which; Nothing at the end of input.
playOrDraw :: (Monad m) => Terminal.Terminal m -> Natural -> m (Maybe Bool)
playOrDraw terminal seat = do
  Terminal.say terminal (Text.pack ("Seat " <> show seat <> ", play first or draw?"))
  typed <- Terminal.listen terminal
  case fmap (Text.toLower . Text.strip) typed of
    Nothing -> pure Nothing
    Just word
      | word `elem` fmap Text.pack ["play", "p"] -> pure (Just True)
      | word `elem` fmap Text.pack ["draw", "d"] -> pure (Just False)
      | otherwise -> Terminal.say terminal (Text.pack "Type play or draw.") >> playOrDraw terminal seat
