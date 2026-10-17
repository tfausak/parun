{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Scenario where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Pawl.Codec.Board as Board
import qualified Pawl.Codec.Check as Check
import qualified Pawl.Codec.Entrant as Entrant
import qualified Pawl.Codec.Timed as Timed
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Scenario as Scenario
import qualified Pawl.Types.Start as Start

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
