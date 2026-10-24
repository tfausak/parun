{-# LANGUAGE GADTs #-}

-- | A played game as a scenario: its decks, and each answer as the timeline
-- entry `parun scenario` replays it from.
module Parun.Play.Record where

import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.DeckList as DeckList
import qualified Parun.Engine.Driver as Driver
import qualified Parun.Engine.Game as Game
import qualified Parun.Extra.Int as Int
import qualified Parun.Scenario as Scenario
import qualified Parun.Scenario.Prompt as Scenario.Prompt
import qualified Parun.Scenario.Reply as Reply
import qualified Parun.Types.Answer as Answer
import qualified Parun.Types.Asked as Asked
import qualified Parun.Types.Card as Card
import qualified Parun.Types.Concession as Concession
import qualified Parun.Types.Deck as Deck
import qualified Parun.Types.Entrant as Entrant
import qualified Parun.Types.Entry as Entry
import qualified Parun.Types.Face as Face
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Label as Label
import qualified Parun.Types.Move as Move
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Observer as Observer
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Reference as Reference
import qualified Parun.Types.Scenario as Scenario.Type
import qualified Parun.Types.Start as Start
import qualified Parun.Types.Timed as Timed
import qualified Parun.Types.When as When

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
