-- Covers: Parun.Engine.Seating's misseated (CR 805.1, 808.2, 809.1, 809.2,
-- 809.6, 809.6a, 811.3) and its refusal through Parun.Engine.Emperor's setUp,
-- and Parun.Engine.Setup.randomSeating's Free-for-All draw (CR 806.3); its
-- Grand Melee draw is Parun.GrandMeleeSpec's.
-- The scenario board's refusal is Parun.ScenarioSpec's.
--
-- Seats are PlayerIds 0 up, in turn order; a team list gives each seat's team.
module Parun.SeatingSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Parun.Engine.AlternatingTeams as AlternatingTeams
import qualified Parun.Engine.Emperor as Emperor
import qualified Parun.Engine.Engine as Engine
import qualified Parun.Engine.Seating as Seating
import qualified Parun.Engine.Setup as Setup
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Registry as Registry
import qualified Parun.Spec as Spec
import qualified Parun.Support as S
import qualified Parun.Types.Emperors as Emperors
import qualified Parun.Types.GameSettings as GameSettings
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RangeOfInfluence as RangeOfInfluence
import qualified Parun.Types.TeamId as TeamId
import qualified Parun.Types.Teams as Teams

spec :: (Monad m, Monad n) => Spec.Spec m n -> Registry.Registry m -> n ()
spec s registry = Spec.describe s "Seating" $ do
  -- CR 806.3: three seats on no team, bob's and carol's drawn at random as the
  -- last candidate, sit alice, carol, bob, and carol takes the next turn. A
  -- game on teams draws no seat.
  Spec.it s "CR 806.3 a Free-for-All game seats its players at random" $ do
    forest <- S.printingOf s registry "Forest"
    let (started, drawnFrom) = S.newGameDrawingLast forest (game 3 GameSettings.plain)
        (teamed, teamDraws) = S.newGameDrawingLast forest (teamGame [0, 0, 1])
    Spec.assertEqWith s "CR 806.3 the seats after alice drawn" drawnFrom [[seat 1, seat 2]]
    Spec.assertEqWith s "CR 806.3 the seating drawn" (GameState.turnOrder started) [seat 0, seat 2, seat 1]
    Spec.assertEqWith s "CR 806.3 carol takes the next turn" (nextTurn started) (seat 2)
    Spec.assertEqWith s "CR 808.2 a team game draws no seat" teamDraws []
    Spec.assertEqWith s "CR 808.2 and keeps its seating" (GameState.turnOrder teamed) [seat 0, seat 1, seat 2]

  -- CR 808.2: two teams of two seated alternately split both. Seat 2 opens
  -- team 0's second run. The same seating is CR 811.3's, so as an Alternating
  -- Teams game it starts.
  Spec.it s "CR 808.2 a team split across the table is refused" $ do
    Spec.assertEqWith s "CR 808.2 seat 2 opens team 0's second run" (Seating.misseated (teamGame [0, 1, 0, 1])) (Just (seat 2))
    Spec.assertEqWith s "CR 808.2 each team side by side starts" (Seating.misseated (teamGame [0, 0, 1, 1])) Nothing
    Spec.assertEqWith
      s
      "CR 811.3 the alternating seating starts an Alternating Teams game"
      (fmap Seating.misseated (AlternatingTeams.setUp (teamsOf [0, 1, 0, 1]) (game 4 GameSettings.plain)))
      (Just Nothing)

  -- CR 811.3: an Alternating Teams game with each team side by side, as a
  -- scenario board can write it, names its first seat.
  Spec.it s "CR 811.3 an Alternating Teams game with teammates side by side is refused" $
    Spec.assertEqWith s "CR 811.3 seat 0" (Seating.misseated (game 4 GameSettings.plain {GameSettings.teams = teamsOf [0, 0, 1, 1], GameSettings.alternatingTeams = True})) (Just (seat 0))

  -- The table is a circle: seats 0, 1 and 3 are one run round it.
  Spec.it s "CR 808.2 a team sits together across the end of the turn order" $
    Spec.assertEqWith s "CR 808.2 wrapping" (Seating.misseated (teamGame [0, 0, 1, 0])) Nothing

  -- CR 808.2: seat 1, on no team, sits between team 0's seats 0 and 2.
  Spec.it s "CR 808.2 a teamless seat between teammates splits the team" $
    Spec.assertEqWith s "CR 808.2 seat 2 opens team 0's second run" (Seating.misseated (gameWithTeams (Teams.MkTeams (Map.fromList [(seat 0, team 0), (seat 2, team 0), (seat 3, team 1), (seat 4, team 1)])) 5)) (Just (seat 2))

  -- CR 809.2: two teams of three, each emperor between two generals of their
  -- own, is setUp's game; an emperor at a team's edge is refused.
  Spec.it s "CR 809.2 an emperor sits in the middle of their team" $ do
    Spec.assertEqWith s "CR 809.2 emperors at seats 1 and 4 start" (fmap Seating.misseated (emperorGame [0, 0, 0, 1, 1, 1] [1, 4])) (Just Nothing)
    Spec.assertEqWith s "CR 809.2 an emperor at seat 0, team 0's edge, is refused" (fmap Seating.misseated (emperorGame [0, 0, 0, 1, 1, 1] [0, 4])) Nothing
    -- At range 1 apiece no emperor reaches another, so only the edge is wrong.
    Spec.assertEqWith s "CR 809.2 seat 0, at range 1, names itself" (Seating.misseated (withRanges [0, 0, 0, 1, 1, 1] [0, 4])) (Just (seat 0))

  -- CR 809.2 / 809.6, decisions.md "The middle seat of an even-sized Emperor
  -- team": two teams of four. Either centre seat is the middle; the edge isn't.
  Spec.it s "CR 809.6 an even-sized team's emperor sits in either centre seat" $ do
    Spec.assertEqWith s "seats 1 and 5, each its team's second seat, start" (fmap Seating.misseated (emperorGame [0, 0, 0, 0, 1, 1, 1, 1] [1, 5])) (Just Nothing)
    Spec.assertEqWith s "seat 3, team 0's edge, is refused" (fmap Seating.misseated (emperorGame [0, 0, 0, 0, 1, 1, 1, 1] [3, 5])) Nothing

  -- CR 809.6: teams of three and two are not equally sized; seat 3 is the
  -- first of the team of a size other than seat 0's.
  Spec.it s "CR 809.6 an Emperor game's teams are equally sized" $
    Spec.assertEqWith s "CR 809.6 seat 3" (Seating.misseated (withEmperors [0, 0, 0, 1, 1] [1, 4])) (Just (seat 3))

  -- CR 809.2: a team with no emperor names its first seat.
  Spec.it s "CR 809.2 each team has an emperor" $
    Spec.assertEqWith s "CR 809.2 seat 3" (Seating.misseated (withEmperors [0, 0, 0, 1, 1, 1] [1])) (Just (seat 3))

  -- CR 809.6a: setUp's game, with seat 1's range widened to 3, reaches seat
  -- 4's emperor. A two-team game of two has no second opposing general for
  -- either emperor, whose range stays unlimited, so setUp refuses it.
  Spec.it s "CR 809.6a no emperor begins within another emperor's range of influence" $ do
    let widened = fmap (\gs -> gs {GameState.settings = (GameState.settings gs) {GameSettings.rangeOfInfluence = RangeOfInfluence.MkRangeOfInfluence (Map.insert (seat 1) 3 (RangeOfInfluence.unwrap (GameSettings.rangeOfInfluence (GameState.settings gs))))}}) (emperorGame [0, 0, 0, 1, 1, 1] [1, 4])
    Spec.assertEqWith s "CR 809.6a seat 4 is within seat 1's range" (fmap Seating.misseated widened) (Just (Just (seat 4)))
    Spec.assertEqWith s "CR 809.6a two teams of two are refused" (fmap Seating.misseated (emperorGame [0, 0, 1, 1] [0, 2])) Nothing
  where
    seat = PlayerId.MkPlayerId
    -- Who takes the turn after `gs0`'s, at most forty steps on.
    nextTurn gs0 =
      let go budget gs
            | budget <= (0 :: Int) || GameState.turnNumber gs /= GameState.turnNumber gs0 = GameState.activePlayer gs
            | otherwise = go (budget - 1) (S.runPure S.identityAnswer gs Engine.runStep)
       in go 40 gs0
    team = TeamId.MkTeamId
    game n settings = Setup.gameWith settings (seat 0 NonEmpty.:| fmap seat [1 .. n - 1])
    teamsOf ts = Teams.MkTeams (Map.fromList (zip (fmap seat [0 ..]) (fmap team ts)))
    gameWithTeams teams n = game n GameSettings.plain {GameSettings.teams = teams}
    teamGame ts = gameWithTeams (teamsOf ts) (Natural.length ts)
    emperorsOf es = Emperors.MkEmperors (Map.fromList (zip (fmap team [0 ..]) (fmap seat es)))
    -- Emperor.setUp's game, Nothing where it refuses the seating.
    emperorGame ts es = Emperor.setUp (teamsOf ts) (emperorsOf es) (game (Natural.length ts) GameSettings.plain)
    -- The teams and emperors at a range of 1 apiece.
    withRanges ts es = withEmperors ts es `withRange` RangeOfInfluence.MkRangeOfInfluence (Map.fromList [(seat i, 1) | i <- [0 .. Natural.length ts - 1]])
    withRange gs ranges = gs {GameState.settings = (GameState.settings gs) {GameSettings.rangeOfInfluence = ranges}}
    -- The teams and emperors alone, with no range of influence.
    withEmperors ts es = game (Natural.length ts) GameSettings.plain {GameSettings.teams = teamsOf ts, GameSettings.emperors = emperorsOf es}
