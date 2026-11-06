-- Covers Parun.Decks and data/decks: every shipped deck list and set list
-- reads, and the Portal and Starter sets' starter pairs each play a whole game
-- that replays.
module Parun.DecksSpec where

import qualified Control.Exception as Exception
import qualified Control.Monad as Monad
import qualified Control.Monad.IO.Class as MonadIO
import qualified Data.Either as Either
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Parun.DeckList as DeckList
import qualified Parun.Decks as Decks
import qualified Parun.RecordSpec as RecordSpec
import qualified Parun.Registry as Registry
import qualified Parun.Scenario as Scenario
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.GameState as GameState

spec :: (MonadIO.MonadIO n) => Spec.Spec IO n -> Registry.Registry IO -> n ()
spec s registry = do
  -- Listed, not read: each case reads its own file.
  root <- MonadIO.liftIO Decks.defaultRoot
  decks <- MonadIO.liftIO (Decks.listRoot root)
  Spec.describe s "Decks" $ do
    Spec.it s "the listing reaches a set's own directory" $
      Spec.assertEqWith s "sets/m15/all.txt listed" ((root <> "/sets/m15/all.txt") `elem` decks) True

    Monad.forM_ decks $ \path -> Spec.it s (drop (length root + 1) path <> " reads") $ do
      contents <- Decks.loadFile path
      parsed <- either (pure . Left . (: []) . Text.unpack) (fmap (either (Left . (: []) . Exception.displayException) (either (Left . fmap (Text.unpack . DeckList.explain)) Right)) . DeckList.parse registry) contents
      Spec.assertEqWith s (path <> ": problems") (Either.fromLeft [] parsed) []

    let starters = ("starter-1", "starter-2")
    Monad.forM_ [("Portal", "por", starters), ("Portal Second Age", "p02", starters), ("Portal Three Kingdoms", "ptk", starters), ("Starter 1999", "s99", starters), ("Starter 2000", "s00", starters), ("Introductory Two-Player Set", "itp", ("kazzs-first-deck", "zakks-first-deck"))] $ \(set, code, (first, second)) ->
      Spec.it s ("two bots finish a game with the " <> set <> " starter decks, and it replays clean") $ do
        let read' name = do
              contents <- Decks.loadFile (root <> "/sets/" <> code <> name)
              either (const (pure (Left []))) (fmap (Either.fromRight (Left [])) . DeckList.parse registry) contents
        decksRead <- (,) <$> read' ("/" <> first <> ".txt") <*> read' ("/" <> second <> ".txt")
        case decksRead of
          (Right one, Right two) -> played (S.alice, one) (S.bob, two)
          _ -> Spec.assertFailure s "the starter decks did not read"
  where
    played seatOne seatTwo = do
      let matchup = seatOne NonEmpty.:| [seatTwo]
          (outcome, timeline) = RecordSpec.recorded RecordSpec.bots matchup
      replayed <- Scenario.run registry (RecordSpec.saved matchup timeline)
      case (outcome, replayed) of
        (Right (result, _), Right final) -> Spec.assertEqWith s "same result" (GameState.result final) (Just result)
        (_, Left failure) -> Spec.assertFailure s (Text.unpack (Scenario.render failure))
        (Left reason, _) -> Spec.assertFailure s (Text.unpack reason)
