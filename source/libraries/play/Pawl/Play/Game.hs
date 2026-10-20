-- | A whole game: each seat answered by its own answerer (a person at the
-- terminal, a program over lines, or the random bot), chance by the
-- generator.
module Pawl.Play.Game where

import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.Class as Trans
import qualified Control.Monad.Trans.Except as Except
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.Engine.Driver as Driver
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Chance as Chance
import qualified Pawl.Play.Client as Client
import qualified Pawl.Play.Protocol as Protocol
import qualified Pawl.Play.SplitMix as SplitMix.Play
import qualified Pawl.Types.Answerer as Answerer
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.Observer as Observer
import qualified Pawl.Types.PlayOptions as PlayOptions
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.SplitMix as SplitMix
import qualified Pawl.Types.Terminal as Terminal

-- | The generator over the client's monad.
type Play m = State.StateT SplitMix.SplitMix (Client.Client m)

-- | A person at the terminal, reading cards' printed text from the card data.
human :: (Monad m) => Terminal.Terminal m -> (CardName.CardName -> Maybe Card.Card) -> Answerer.Answerer (Play m)
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
-- through 'Bot.playsFirst' and a person at the terminal. Nothing at the end
-- of input.
--
-- Not implemented: asking a seat over the line protocol, so with --json seat
-- 1 plays first (#5374).
starter :: (Monad m) => Terminal.Terminal m -> PlayOptions.PlayOptions -> State.StateT SplitMix.SplitMix m (Maybe Natural)
starter terminal options = case PlayOptions.first options of
  Just seat -> pure (Just seat)
  Nothing | PlayOptions.json options -> pure (Just 1)
  Nothing -> do
    chooser <- SplitMix.Play.pick (1 NonEmpty.:| [2])
    Trans.lift (Terminal.say terminal (Text.pack ("Seat " <> show chooser <> " was picked at random to choose who plays first.")))
    plays <-
      if Set.member chooser (PlayOptions.bots options)
        then fmap Just Bot.playsFirst
        else Trans.lift (playOrDraw terminal chooser)
    Monad.forM plays $ \chooses -> do
      let seat = if chooses == (chooser == 1) then 1 else 2 :: Natural
      Trans.lift (Terminal.say terminal (Text.pack ("Seat " <> show seat <> " plays first.")))
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
