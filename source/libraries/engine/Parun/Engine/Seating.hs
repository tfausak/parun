-- | CR 805.1 / 808.2 / 809 / 811.3: whether a game's seating
-- (GameState.turnOrder) is one its teams and emperors allow.
module Parun.Engine.Seating where

import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Parun.Engine.AlternatingTeams as AlternatingTeams
import qualified Parun.Engine.Game as Game
import qualified Parun.Types.Emperors as Emperors
import qualified Parun.Types.GameSettings as GameSettings
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.PlayerId (PlayerId)
import Parun.Types.TeamId (TeamId)
import qualified Parun.Types.Teams as Teams

-- | The first seat this game's seating places against the rules, or Nothing
-- when they allow it. An Alternating Teams game is AlternatingTeams.seated's
-- (CR 811.3) and names its first seat. Any other has each team sitting
-- together (CR 805.1, 808.2, 810.3) and names the seat opening a team's second
-- run; an Emperor game is then emperorFault's too.
misseated :: GameState -> Maybe PlayerId
misseated gs =
  let settings = GameState.settings gs
      teams = GameSettings.teams settings
      seats = GameState.turnOrder gs
   in if GameSettings.alternatingTeams settings
        then if AlternatingTeams.seated teams seats then Nothing else Maybe.listToMaybe seats
        else
          let opened = openings teams seats
           in case Maybe.listToMaybe [seat | ((seat, team), earlier) <- zip opened (List.inits opened), team `elem` fmap snd earlier] of
                Just seat -> Just seat
                Nothing
                  | Map.null (Emperors.unwrap (GameSettings.emperors settings)) -> Nothing
                  | otherwise -> emperorFault gs

-- | Each seat opening a run of one team's seats round the table, the seat to
-- its right being on another team or none, in turn order with its team.
openings :: Teams.Teams -> [PlayerId] -> [(PlayerId, TeamId)]
openings teams seats =
  let previous = drop (length seats - 1) seats <> seats
   in [(seat, team) | (seat, prior) <- zip seats previous, Just team <- [Teams.teamOf teams seat], Teams.teamOf teams prior /= Just team]

-- | An Emperor game's seating faults over a table whose teams each sit
-- together, first found first: a seat on no team, or a table of fewer than two
-- teams (CR 809.1), names its first seat; a team of another size than the first
-- seat's (CR 809.6) or with no emperor of its own (CR 809.2) its first seat; an
-- emperor not in the middle of its team (CR 809.2), or within another emperor's
-- range of influence (CR 809.6a), that emperor.
--
-- An even-sized team's middle is either of its two centre seats; see "The
-- middle seat of an even-sized Emperor team" in docs/decisions.md.
emperorFault :: GameState -> Maybe PlayerId
emperorFault gs =
  let settings = GameState.settings gs
      teams = GameSettings.teams settings
      emperors = Emperors.unwrap (GameSettings.emperors settings)
      seats = GameState.turnOrder gs
      members team = filter ((== Just team) . Teams.teamOf teams) seats
      byTeam = Map.fromList [(team, members team) | Just team <- fmap (Teams.teamOf teams) seats]
      firstOf team = Maybe.listToMaybe (members team)
      size = maybe 0 length (Maybe.listToMaybe seats >>= Teams.teamOf teams >>= (`Map.lookup` byTeam))
      ownEmperor team = case Map.lookup team emperors of
        Just emperor -> Teams.teamOf teams emperor == Just team
        Nothing -> False
      -- The team's seats from its opening, round the table to its left.
      runOf (open, team) = case break (== open) seats of
        (before, after) -> filter ((== Just team) . Teams.teamOf teams) (after <> before)
      centred run emperor = case List.elemIndex emperor run of
        Just i -> abs (2 * i - (length run - 1)) <= 1
        Nothing -> False
      offCentre = [emperor | opened@(_, team) <- openings teams seats, Just emperor <- [Map.lookup team emperors], not (centred (runOf opened) emperor)]
      exposed = [emperor | emperor <- Map.elems emperors, other <- Map.elems emperors, other /= emperor, Game.inRangeOf other emperor gs]
   in Foldable.asum
        [ List.find (Maybe.isNothing . Teams.teamOf teams) seats,
          if Map.size byTeam < 2 then Maybe.listToMaybe seats else Nothing,
          Foldable.asum [firstOf team | (team, seated) <- Map.toList byTeam, length seated /= size],
          Foldable.asum [firstOf team | team <- Map.keys byTeam, not (ownEmperor team)],
          Maybe.listToMaybe offCentre,
          Maybe.listToMaybe exposed
        ]
