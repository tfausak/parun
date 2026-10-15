module Pawl.Engine.Ante where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Types.CardIdentity as CardIdentity
import qualified Pawl.Types.Face as Face
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Object as Object
import Pawl.Types.ObjectId (ObjectId)
import Pawl.Types.PlayerId (PlayerId)
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.Teams as Teams

-- | CR 407.3: when not playing for ante, an ante card "can't be brought into
-- the game from outside the game". Read off the printed face's flag, never its
-- text.
barred :: GameSettings.GameSettings -> Face.Face card -> Bool
barred settings face = Face.anteOnly face && not (GameSettings.ante settings)

-- | CR 108.3 / 407.3: every card in the game whose owner is not the player who
-- began the game owning it, as that player and its owner. A token, an emblem
-- and a copy carry no identity, so never appear.
--
-- Not implemented: a card that left the game with a departed owner (#4847),
-- and each card of a merged or melded permanent but the one whose identity the
-- permanent carries (#5055).
ownershipChanges :: GameState.GameState -> Map.Map ObjectId (PlayerId, PlayerId)
ownershipChanges gs =
  let changed obj = case Object.identity obj of
        Just identity | CardIdentity.startingOwner identity /= Object.owner obj -> Just (CardIdentity.startingOwner identity, Object.owner obj)
        _ -> Nothing
   in Map.mapMaybe changed (GameState.objects gs)

-- | CR 407.2: "at the end of the game, the winner becomes the owner of all the
-- cards in the ante zone", as Departure.settle sets the result. A draw has no
-- winner (CR 104.4a), so every card keeps its owner.
--
-- CR 104.2c: a team's win makes every player on it a winner, a departed one
-- included, so the team decides which of them takes each card, asked card by
-- card and elided for a team of one. CR 805.2 gives a team's choice to its
-- primary player; without the shared team turns option no rule names who
-- speaks for a team, and its first seat still playing does. The scenario
-- "CR 407.2 / 104.2c the winning team's primary player shares out the ante"
-- proves it.
payOut :: Game ()
payOut = do
  gs <- State.get
  let ante = Set.toList (GameState.ante gs)
      payTo oid winner = State.modify' (Game.setOwner oid winner)
  case GameState.result gs of
    Just (Result.Won winner) -> Foldable.traverse_ (`payTo` winner) ante
    Just (Result.TeamWon team) -> do
      let onTeam pid = Teams.teamOf (Game.teams gs) pid == Just team
          winners = filter onTeam (GameState.turnOrder gs)
      case filter onTeam (Game.stillPlayingInOrder gs) of
        [] -> pure ()
        speaker : _ ->
          Foldable.for_ ante $ \oid -> do
            taker <- Game.chooseAmong (\decider asked -> Prompt.ChoosePlayer decider asked oid) (Game.primaryOf gs speaker) winners
            Foldable.traverse_ (payTo oid) taker
    Just Result.Drawn -> pure ()
    Nothing -> pure ()
