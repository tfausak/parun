{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Scenario where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Board as Board
import qualified Parun.Codec.Check as Check
import qualified Parun.Codec.Entrant as Entrant
import qualified Parun.Codec.Timed as Timed
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Scenario as Scenario
import qualified Parun.Types.Start as Start

codec :: Codec.Codec Scenario.Scenario
codec = Fields.object $ do
  description <- Fields.required "description" Common.text Scenario.description
  start <- startFields
  timeline <- Fields.defaulted "timeline" Seq.empty (Common.seq Timed.codec) Scenario.timeline
  final <- Fields.defaulted "final" Seq.empty (Common.seq Check.codec) Scenario.final
  pure
    Scenario.MkScenario
      { Scenario.description = description,
        Scenario.start = start,
        Scenario.timeline = timeline,
        Scenario.final = final
      }

-- | A board under "board", or the decks of a new game under "game"; exactly
-- one.
startFields :: Fields.Fields Scenario.Scenario Start.Start
startFields =
  let board = Fields.defaulted "board" Nothing (Common.maybe Board.codec) (boardOf . Scenario.start)
      game = Fields.defaulted "game" Nothing (Common.maybe (Common.nonEmpty Entrant.codec)) (gameOf . Scenario.start)
      both = (,) <$> board <*> game
   in both
        { Fields.decode = \pairs -> do
            found <- Fields.decode both pairs
            case found of
              (Just b, Nothing) -> Right (Start.FromBoard b)
              (Nothing, Just g) -> Right (Start.FromDecks g)
              _ -> Left (Text.pack "expected exactly one of board and game")
        }
  where
    boardOf start = case start of
      Start.FromBoard b -> Just b
      Start.FromDecks _ -> Nothing
    gameOf start = case start of
      Start.FromBoard _ -> Nothing
      Start.FromDecks g -> Just g
