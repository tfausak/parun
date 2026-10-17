{-# LANGUAGE GADTs #-}

-- | A played game as a scenario: its decks, and each answer as the timeline
-- entry `pawl scenario` replays it from.
module Pawl.Play.Record where

import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Pawl.DeckList as DeckList
import qualified Pawl.Engine.Driver as Driver
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Extra.Int as Int
import qualified Pawl.Scenario as Scenario
import qualified Pawl.Scenario.Prompt as Scenario.Prompt
import qualified Pawl.Scenario.Reply as Reply
import qualified Pawl.Types.Answer as Answer
import qualified Pawl.Types.Asked as Asked
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.Concession as Concession
import qualified Pawl.Types.Deck as Deck
import qualified Pawl.Types.Entrant as Entrant
import qualified Pawl.Types.Entry as Entry
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Label as Label
import qualified Pawl.Types.Move as Move
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.Observer as Observer
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Reference as Reference
import qualified Pawl.Types.Scenario as Scenario.Type
import qualified Pawl.Types.Start as Start
import qualified Pawl.Types.Timed as Timed
import qualified Pawl.Types.When as When

-- | Hands each answer's entry to `sink` as it is taken, so a game cut short
-- keeps every entry up to the cut.
recording :: (Applicative m) => Map.Map PlayerId.PlayerId Label.Label -> (Timed.Timed -> m ()) -> Observer.Observer m
recording seats sink =
  Observer.MkObserver
    { Observer.before = \_ -> pure (),
      Observer.after = \asked answer -> maybe (pure ()) sink (entryFor seats asked answer)
    }

-- | An answer as the entry that replays it: an Answer move at the moment of
-- its seat, or the active player's for chance (where the runner looks), CR
-- 104.3a's Concede move when a seat concedes, and nothing for a standing
-- refusal to concede or the interpreter's questions.
entryFor :: Map.Map PlayerId.PlayerId Label.Label -> Asked.Asked r -> r -> Maybe Timed.Timed
entryFor seats asked answer = case prompt of
  Prompt.Concede pid
    | answer == Concession.Concedes -> Just (at pid Move.Concede)
    | otherwise -> Nothing
  _
    | Scenario.recorded prompt ->
        let replied = Reply.encode (Reply.shapeOf prompt) (namer seats gs) answer
         in Just (at (Maybe.fromMaybe (GameState.activePlayer gs) (Driver.deciderOf prompt)) (Move.Answer (Answer.MkAnswer (Scenario.Prompt.kindOf prompt) replied False)))
    | otherwise -> Nothing
  where
    prompt = Asked.prompt asked
    gs = Asked.game asked
    at pid move = Timed.MkTimed (When.MkWhen (GameState.turnNumber gs) (GameState.phase gs) (labelOf seats pid)) Nothing (Entry.Do move)

-- | Objects by card name and creation order, as the runner reads them back
-- on the same state; players by their seat's label.
--
-- Not implemented: naming an object with no card (#5232).
namer :: Map.Map PlayerId.PlayerId Label.Label -> GameState.GameState -> Reply.Namer
namer seats gs =
  Reply.MkNamer
    { Reply.nameObject = \oid -> case Game.cardOf oid gs of
        Just card ->
          let name = Face.name (NonEmpty.head (Card.faces card))
           in Reference.Printed name (maybe 0 ((+ 1) . Int.toNaturalSaturating) (List.elemIndex oid (Scenario.namedObjects name gs)))
        Nothing -> Reference.Labelled (Label.MkLabel (Text.pack ("object " <> show (ObjectId.unwrap oid)))),
      Reply.namePlayer = labelOf seats
    }

labelOf :: Map.Map PlayerId.PlayerId Label.Label -> PlayerId.PlayerId -> Label.Label
labelOf seats pid = Maybe.fromMaybe (Label.MkLabel (Text.pack ("player " <> show (PlayerId.unwrap pid)))) (Map.lookup pid seats)

-- | The scenario a game played from these decks replays as.
scenario :: Text.Text -> NonEmpty.NonEmpty (Label.Label, Deck.Deck) -> Seq.Seq Timed.Timed -> Scenario.Type.Scenario
scenario description entrants timeline =
  Scenario.Type.MkScenario
    { Scenario.Type.description = description,
      Scenario.Type.start = Start.FromDecks (fmap (\(label, deck) -> Entrant.MkEntrant label (Text.lines (DeckList.render deck))) entrants),
      Scenario.Type.timeline = timeline,
      Scenario.Type.final = Seq.empty
    }
