-- Covers Pawl.Decks and data/decks: every shipped deck list reads, and the
-- Portal starter decks play a whole game that replays.
module Pawl.DecksSpec where

import qualified Control.Monad as Monad
import qualified Control.Monad.IO.Class as MonadIO
import qualified Data.Either as Either
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Text as Text
import qualified Pawl.DeckList as DeckList
import qualified Pawl.Decks as Decks
import qualified Pawl.RecordSpec as RecordSpec
import qualified Pawl.Registry as Registry
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Spec as Spec
import qualified Pawl.Support as S
import qualified Pawl.Types.GameState as GameState

spec :: (MonadIO.MonadIO n) => Spec.Spec IO n -> Registry.Registry IO -> n ()
spec s registry = do
  -- Listed, not read: each case reads its own file.
  root <- MonadIO.liftIO Decks.defaultRoot
  paths <- MonadIO.liftIO (Decks.listRoot root)
  Spec.describe s "Decks" $ do
    Monad.forM_ paths $ \path -> Spec.it s (reverse (takeWhile (/= '/') (reverse path)) <> " reads") $ do
      contents <- Decks.loadFile path
      parsed <- either (pure . Left . (: []) . Text.unpack) (fmap (either (Left . fmap (Text.unpack . DeckList.explain)) Right) . DeckList.parse registry) contents
      Spec.assertEqWith s (path <> ": problems") (Either.fromLeft [] parsed) []

    Spec.it s "two bots finish a game with the Portal starter decks, and it replays clean" $ do
      let read' name = do
            contents <- Decks.loadFile (root <> "/" <> name)
            either (const (pure (Left []))) (DeckList.parse registry) contents
      decksRead <- (,) <$> read' "portal-starter-1.txt" <*> read' "portal-starter-2.txt"
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
