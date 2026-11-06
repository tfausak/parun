module Parun.Engine.Ante where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.Foldable as Foldable
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.CardIdentity as CardIdentity
import qualified Parun.Types.ComponentCard as ComponentCard
import qualified Parun.Types.Face as Face
import Parun.Types.Game (Game)
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.Object as Object
import qualified Parun.Types.OwnershipChange as OwnershipChange
import qualified Parun.Types.PrintingId as PrintingId
import qualified Parun.Types.Prompt as Prompt
import qualified Parun.Types.Result as Result
import qualified Parun.Types.Teams as Teams

-- | CR 407.3: when not playing for ante, an ante card "can't be brought into
-- the game from outside the game". Read off the printed face's flag, never its
-- text.
barred :: GameSettings.GameSettings -> Face.Face card -> Bool
barred settings face = Face.anteOnly face && not (GameSettings.ante settings)

-- | CR 108.3: the cards an object is, each with its printing and identity. A
-- merged or melded permanent (CR 731.2, 701.42a) is one object made of several
-- cards, each with its own identity (Parun.Types.ComponentCard). A token, an
-- emblem and a copy carry no identity, so are none.
cardsOf :: Object.Object -> [(PrintingId.PrintingId, CardIdentity.CardIdentity)]
cardsOf obj =
  let components = Game.componentsOf (Object.source obj)
   in if Seq.null components
        then Maybe.maybeToList ((,) <$> Game.printingIdOfSource (Object.source obj) <*> Object.identity obj)
        else [(ComponentCard.printing card, identity) | Just card <- fmap Game.cardOfComponent (Foldable.toList components), Just identity <- [ComponentCard.identity card]]

-- | Whether some card of the object is owned by a player who did not begin the
-- game owning it (CR 108.3, 407.3).
ownerChanged :: Object.Object -> Bool
ownerChanged obj = any (\(_, identity) -> CardIdentity.startingOwner identity /= Object.owner obj) (cardsOf obj)

-- | CR 108.3 / 407.3: every card whose owner is not the player who began the
-- game owning it, one row per card: each card of an object in the game, owned
-- by the object's owner, the one owner parun keeps for a merged or melded
-- permanent, and each card that left the game with its owner (CR 800.4a,
-- GameState.departedCards). The scenario "CR 108.3 / 731.2 a merged permanent
-- on the battlefield reports the card whose owner changed" proves the merged
-- case, and "CR 800.4a Tempest Efreet's new owner concedes and the report still
-- lists it" the departed one.
ownershipChanges :: GameState.GameState -> Seq.Seq OwnershipChange.OwnershipChange
ownershipChanges gs =
  let changed oid obj (printing, identity)
        | CardIdentity.startingOwner identity /= Object.owner obj = Just (OwnershipChange.MkOwnershipChange oid printing (CardIdentity.startingOwner identity) (Object.owner obj))
        | otherwise = Nothing
   in foldMap (\(oid, obj) -> Seq.fromList (Maybe.mapMaybe (changed oid obj) (cardsOf obj))) (Map.toAscList (Map.union (GameState.objects gs) (GameState.departedCards gs)))

-- | CR 407.2: "at the end of the game, the winner becomes the owner of all the
-- cards in the ante zone", as Departure.settle sets the result. A draw has no
-- winner (CR 104.4a), so every card keeps its owner.
--
-- CR 104.2c: a team's win makes every player on it a winner, a departed one
-- included, so the team decides which of them takes each card, asked card by
-- card and elided for a team of one. CR 805.2 gives a team's choice to its
-- primary player; without the shared team turns option no rule names who
-- speaks for a team, and its first seat still playing does (docs/decisions.md,
-- "Who on a winning team takes the ante"). The scenario
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
