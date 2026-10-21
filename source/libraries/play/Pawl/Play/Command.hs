-- | `pawl play`: a game of two seats at one terminal, either of them the
-- random bot, or both over the line protocol with --json.
module Pawl.Play.Command where

import qualified Control.Exception as Exception
import qualified Control.Monad as Monad
import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Bifunctor as Bifunctor
import qualified Data.ByteString as ByteString
import qualified Data.Functor.Identity as Identity
import qualified Data.IORef as IORef
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Encoding
import qualified Data.Text.IO as TextIO
import qualified Data.Time.Clock.System as Clock
import Numeric.Natural (Natural)
import qualified Pawl.Codec.Scenario as Codec.Scenario
import qualified Pawl.DeckList as DeckList
import qualified Pawl.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Pawl.Extra.Integer as Integer
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Play.Bot as Bot
import qualified Pawl.Play.Game as Game
import qualified Pawl.Play.Protocol as Protocol
import qualified Pawl.Play.Record as Record
import qualified Pawl.Play.Render as Render
import qualified Pawl.Play.SplitMix as SplitMix.Play
import qualified Pawl.Registry as Registry
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.Hotseat as Hotseat
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.PlayOptions as PlayOptions
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.SplitMix as SplitMix
import qualified Pawl.Types.Terminal as Terminal
import qualified System.Console.GetOpt as GetOpt
import qualified System.Exit as Exit
import qualified System.IO as IO
import qualified Text.Read as Read

main :: [String] -> IO ()
main arguments = case GetOpt.getOpt GetOpt.Permute flags arguments of
  (updates, [one, two], []) -> case foldr (=<<) (Right PlayOptions.none) updates of
    Left problem -> usage [problem]
    Right options -> do
      registry <- Registry.defaultRoot >>= Registry.fileRegistry
      decks <- (,) <$> load registry one <*> load registry two
      play options (Identity.runIdentity . Registry.fetchCard registry) decks
  (_, _, problems) -> usage problems

flags :: [GetOpt.OptDescr (PlayOptions.PlayOptions -> Either String PlayOptions.PlayOptions)]
flags =
  [ GetOpt.Option [] ["seed"] (GetOpt.ReqArg (\s o -> maybe (Left ("not a seed: " <> s)) (\n -> Right o {PlayOptions.seed = Just n}) (Read.readMaybe s)) "N") "the generator's seed; the clock's when absent",
    GetOpt.Option [] ["first"] (GetOpt.ReqArg (\s o -> fmap (\n -> o {PlayOptions.first = Just n}) (seat s)) "1|2") "which seat plays first; a seat picked at random chooses when absent",
    GetOpt.Option [] ["bot"] (GetOpt.ReqArg (\s o -> fmap (\n -> o {PlayOptions.bots = Set.insert n (PlayOptions.bots o)}) (seat s)) "1|2") "a seat the random bot plays",
    GetOpt.Option [] ["json"] (GetOpt.NoArg (\o -> Right o {PlayOptions.json = True})) "speak the line protocol on standard input and output",
    GetOpt.Option [] ["save"] (GetOpt.ReqArg (\s o -> Right o {PlayOptions.save = Just s}) "FILE") "save the game as a scenario, even one cut short",
    GetOpt.Option [] ["no-auto-pass"] (GetOpt.NoArg (\o -> Right o {PlayOptions.autoPass = False})) "ask at every priority, even when passing and mana abilities are all there is"
  ]
  where
    seat s = case Read.readMaybe s of
      Just n | n == 1 || n == 2 -> Right n
      _ -> Left ("not a seat: " <> s)

usage :: [String] -> IO a
usage problems = do
  mapM_ (IO.hPutStr IO.stderr) problems
  IO.hPutStr IO.stderr (GetOpt.usageInfo "usage: pawl play [OPTION...] DECK DECK" flags)
  Exit.exitFailure

-- | A deck list file, as `pawl deck` reads it.
load :: Registry.Registry Identity.Identity -> FilePath -> IO Deck.Deck
load registry path = do
  bytes <- ByteString.readFile path
  contents <- either (\err -> failWith (path <> ": not valid UTF-8: " <> show err)) pure (Encoding.decodeUtf8' bytes)
  case Identity.runIdentity (DeckList.parse registry contents) of
    Left corpus -> failWith (Exception.displayException corpus)
    Right (Left problems) -> do
      mapM_ (TextIO.hPutStrLn IO.stderr . (\p -> Text.pack (path <> ": ") <> DeckList.explain p)) problems
      Exit.exitFailure
    Right (Right deck) -> pure deck

-- | Nanoseconds since the epoch; on macOS only microseconds tick.
nanoseconds :: Clock.SystemTime -> Natural
nanoseconds t = Integer.toNaturalSaturating (toInteger (Clock.systemSeconds t) * 1000000000 + toInteger (Clock.systemNanoseconds t))

play :: PlayOptions.PlayOptions -> (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> (Deck.Deck, Deck.Deck) -> IO ()
play options lookUp (one, two) = do
  IO.hSetBuffering IO.stdout IO.LineBuffering
  seed <- maybe (fmap (SplitMix.Play.fromClock . nanoseconds) Clock.getSystemTime) pure (PlayOptions.seed options)
  IO.hPutStrLn IO.stderr ("Seed " <> show seed <> ".")
  let people = filter (`Set.notMember` PlayOptions.bots options) [1, 2]
  let (tell, ask)
        | PlayOptions.json options = (TextIO.hPutStrLn IO.stderr, Protocol.playOrDraw exchange . idOf)
        | otherwise = (TextIO.putStrLn, Game.playOrDraw terminal)
  (starter, generator) <- State.runStateT (Game.starter tell ask options) (SplitMix.MkSplitMix seed)
  first <- maybe (failWith "end of input") pure starter
  let matchup =
        if first == 2
          then (idOf 2, two) NonEmpty.:| [(idOf 1, one)]
          else (idOf 1, one) NonEmpty.:| [(idOf 2, two)]
      answerer n
        | Set.member n (PlayOptions.bots options) = Bot.bot
        | PlayOptions.json options = Game.wired exchange
        | otherwise = Game.human terminal lookUp
      seats = Map.fromList [(idOf n, answerer n) | n <- [1, 2]]
      screen = Hotseat.fresh {Hotseat.autoPass = PlayOptions.autoPass options}
      hotseat = case people of
        [only] -> screen {Hotseat.facing = Just (idOf only)}
        _ -> screen
  entries <- IORef.newIORef Seq.empty
  let labels = Map.fromList [(idOf n, Label.MkLabel (Text.pack ("player" <> show n))) | n <- [1, 2 :: Natural]]
      observers = [Record.recording labels (Game.underneath . IORef.modifyIORef' entries . flip (Seq.|>)) | Maybe.isJust (PlayOptions.save options)]
      interrupted e = case e of
        Exception.UserInterrupt -> pure (Left (Text.pack "interrupted"))
        _ -> Exception.throwIO e
  outcome <- Exception.catch (Game.run observers seats hotseat generator matchup) interrupted
  Monad.forM_ (PlayOptions.save options) $ \path -> do
    timeline <- IORef.readIORef entries
    let entrants = fmap (Bifunctor.first (Record.labelOf labels)) matchup
        saved = Record.scenario (Text.pack ("Played with pawl play, seed " <> show seed <> ".")) entrants timeline
    ByteString.writeFile path (Encoding.encodeUtf8 (Common.render (Codec.encode Codec.Scenario.codec saved) <> Text.pack "\n"))
    IO.hPutStrLn IO.stderr ("Saved " <> path <> ".")
  case outcome of
    Right (result, _) -> (if PlayOptions.json options then TextIO.hPutStrLn IO.stderr else TextIO.putStrLn) (Render.result result)
    Left reason -> TextIO.hPutStrLn IO.stderr (Text.pack "Stopped: " <> reason <> Text.pack ".")

idOf :: Natural -> PlayerId.PlayerId
idOf n = PlayerId.MkPlayerId (n - 1)

terminal :: Terminal.Terminal IO
terminal =
  Terminal.MkTerminal
    { Terminal.say = TextIO.putStrLn,
      Terminal.listen = do
        IO.hFlush IO.stdout
        done <- IO.isEOF
        if done then pure Nothing else fmap Just TextIO.getLine,
      Terminal.clear = TextIO.putStr (Text.pack "\ESC[2J\ESC[H")
    }

-- | One request line out on standard output, its reply line back.
exchange :: Text.Text -> IO (Maybe Text.Text)
exchange line = TextIO.putStrLn line >> Terminal.listen terminal

failWith :: String -> IO a
failWith problem = IO.hPutStrLn IO.stderr problem >> Exit.exitFailure
