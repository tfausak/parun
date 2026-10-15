module Pawl.Engine.Ante where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Pawl.Engine.Game as Game
import qualified Pawl.Types.CardIdentity as CardIdentity
import qualified Pawl.Types.ComponentCard as ComponentCard
import qualified Pawl.Types.Face as Face
import Pawl.Types.Game (Game)
import qualified Pawl.Types.GameSettings as GameSettings
import qualified Pawl.Types.GameState as GameState
import qualified Pawl.Types.Object as Object
import qualified Pawl.Types.OwnershipChange as OwnershipChange
import qualified Pawl.Types.Prompt as Prompt
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.Teams as Teams

-- | CR 407.3: when not playing for ante, an ante card "can't be brought into
-- the game from outside the game". Read off the printed face's flag, never its
-- text.
barred :: GameSettings.GameSettings -> Face.Face card -> Bool
barred settings face = Face.anteOnly face && not (GameSettings.ante settings)

-- | CR 108.3 / 407.3: every card in the game whose owner is not the player who
-- began the game owning it, one row per card. A merged or melded permanent (CR
-- 730.2, 701.42a) is one object made of several cards, each with its own
-- identity (Pawl.Types.ComponentCard), so each of its cards is read, and owned
-- by the permanent's owner, the one owner pawl keeps for it. A token, an emblem
-- and a copy carry no identity, so never appear. The scenario "CR 108.3 / 730.2
-- a merged permanent on the battlefield reports the card whose owner changed"
-- proves the merged case.
--
-- Not implemented: a card that left the game with a departed owner (#4847).
ownershipChanges :: GameState.GameState -> Seq.Seq OwnershipChange.OwnershipChange
ownershipChanges gs =
  let cardsOf obj =
        let components = Game.componentsOf (Object.source obj)
         in if Seq.null components
              then Seq.fromList (Maybe.maybeToList ((,) <$> Game.printingIdOfSource (Object.source obj) <*> Object.identity obj))
              else Seq.fromList [(ComponentCard.printing card, identity) | Just card <- fmap Game.cardOfComponent (Foldable.toList components), Just identity <- [ComponentCard.identity card]]
      changed oid obj (printing, identity)
        | CardIdentity.startingOwner identity /= Object.owner obj = Just (OwnershipChange.MkOwnershipChange oid printing (CardIdentity.startingOwner identity) (Object.owner obj))
        | otherwise = Nothing
   in foldMap (\(oid, obj) -> Seq.fromList (Maybe.mapMaybe (changed oid obj) (Foldable.toList (cardsOf obj)))) (Map.toAscList (GameState.objects gs))

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
