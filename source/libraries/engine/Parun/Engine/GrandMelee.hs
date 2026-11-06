-- | CR 807: the Grand Melee variant -- its options, CR 807.4's turn markers and
-- CR 807.5a's priority over the stack.
--
-- Not implemented: CR 807.4b's simultaneous turns and CR 807.5's stack per
-- marker. Marker holders take their turns one at a time over the one stack,
-- the next marker in number order going next where its holder can begin
-- (nextMarker, #6117).
module Parun.Engine.GrandMelee where

import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import Numeric.Natural (Natural)
import qualified Parun.Engine.Game as Game
import qualified Parun.Engine.Projection.View as View
import qualified Parun.Extra.Natural as Natural
import qualified Parun.Types.AttackOption as AttackOption
import qualified Parun.Types.ExtraTurn as ExtraTurn
import qualified Parun.Types.GameSettings as GameSettings
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.RangeOfInfluence as RangeOfInfluence
import Parun.Types.TurnMarker (TurnMarker)
import qualified Parun.Types.TurnMarker as TurnMarker

-- | CR 807.2 / 807.4b: a Grand Melee game's options over this game's seating
-- (GameState.turnOrder) -- CR 807.2a's range of 1, CR 807.2b's attack left
-- option and CR 807.2c's options off -- and its turn markers, handed out from
-- the active player.
--
-- Not implemented: CR 807.3's random seating, which is the caller's (#6455).
setUp :: GameState -> GameState
setUp gs =
  handOut
    gs
      { GameState.settings =
          (GameState.settings gs)
            { GameSettings.grandMelee = True,
              GameSettings.rangeOfInfluence = RangeOfInfluence.MkRangeOfInfluence (Map.fromList [(pid, 1) | pid <- GameState.turnOrder gs]),
              GameSettings.attackOption = Just AttackOption.Leftward,
              GameSettings.deployCreatures = False
            }
      }

-- | CR 807.4a / 807.4b: one marker for each full four players, the first to
-- the starting player (the active player) and each next one four seats to the
-- left, numbered in that order; the first marker's turn is the game's first.
-- Nothing outside the variant. Parun.Engine.Setup calls it again once CR
-- 103.1's starting player is settled.
handOut :: GameState -> GameState
handOut gs
  | not (GameSettings.grandMelee (GameState.settings gs)) = gs
  | otherwise =
      let seats = case List.break (== GameState.activePlayer gs) (Game.stillPlayingInOrder gs) of
            (before, after) -> after <> before
          holders = take (Natural.toIntSaturating (markersFor (Natural.length seats))) [pid | (i, pid) <- zip [0 :: Int ..] seats, mod i 4 == 0]
          marker n pid =
            TurnMarker.MkTurnMarker
              { TurnMarker.number = n,
                TurnMarker.holder = pid,
                TurnMarker.underWay = n == 1,
                TurnMarker.owesTurn = n /= 1,
                TurnMarker.removals = 0
              }
       in gs {GameState.turnMarkers = zipWith marker [1 ..] holders}

-- | CR 807.4a: how many markers this many players have, never fewer than one
-- (docs/decisions.md, "Whether a Grand Melee game keeps a turn marker").
markersFor :: Natural -> Natural
markersFor players = max 1 (div players 4)

-- | CR 807.5a: whether a player gets priority for the stack, which is the
-- marker under way's (the active player's) -- that marker, or the controller
-- of an object on the stack, is within their range of influence. Everyone
-- outside the variant.
eligible :: GameState -> PlayerId -> Bool
eligible gs pid =
  not (GameSettings.grandMelee (GameState.settings gs))
    -- CR 800.4j: a departed holder's marker stays at their seat until their
    -- turn ends (CR 807.4c).
    || Game.wasInRangeOf pid (GameState.activePlayer gs) gs
    || any (\controller -> Game.inRangeOf pid controller gs) (Maybe.mapMaybe (`View.controllerOf` gs) (GameState.stack gs))

-- Every other seat, departed ones included, nearest `pid`'s left first.
seatsLeftOf :: PlayerId -> GameState -> [PlayerId]
seatsLeftOf pid gs =
  let order = GameState.turnOrder gs
   in drop 1 (dropWhile (/= pid) order) <> takeWhile (/= pid) order

-- The still-playing players to `pid`'s left, nearest first, `pid` excluded.
leftOf :: PlayerId -> GameState -> [PlayerId]
leftOf pid gs = filter (`List.elem` Game.stillPlaying gs) (seatsLeftOf pid gs)

-- The still-playing players to `pid`'s right, nearest first, `pid` excluded.
rightOf :: PlayerId -> GameState -> [PlayerId]
rightOf pid gs = reverse (leftOf pid gs)

-- Whether another marker is held within three seats of this one, on the side
-- `side` lists. CR 807.4d's seats are the still-playing players'
-- (docs/decisions.md, "Which seats Grand Melee's three-seat window counts").
crowded :: (PlayerId -> GameState -> [PlayerId]) -> TurnMarker -> GameState -> Bool
crowded side marker gs =
  let near = take 3 (side (TurnMarker.holder marker) gs)
   in any (\other -> TurnMarker.number other /= TurnMarker.number marker && List.elem (TurnMarker.holder other) near) (GameState.turnMarkers gs)

-- | CR 807.4d: a marker whose holder can't begin their turn yet.
blocked :: TurnMarker -> GameState -> Bool
blocked = crowded leftOf

overMarker :: Natural -> (TurnMarker -> TurnMarker) -> GameState -> GameState
overMarker n f gs = gs {GameState.turnMarkers = fmap (\m -> if TurnMarker.number m == n then f m else m) (GameState.turnMarkers gs)}

markerNumbered :: Natural -> GameState -> Maybe TurnMarker
markerNumbered n gs = List.find ((== n) . TurnMarker.number) (GameState.turnMarkers gs)

-- CR 807.4c: the marker goes to the player on its holder's left, whose turn
-- under it is still to come.
passLeft :: TurnMarker -> GameState -> GameState
passLeft marker gs = case leftOf (TurnMarker.holder marker) gs of
  next : _ -> overMarker (TurnMarker.number marker) (\m -> m {TurnMarker.holder = next, TurnMarker.underWay = False, TurnMarker.owesTurn = True}) gs
  [] -> overMarker (TurnMarker.number marker) (\m -> m {TurnMarker.underWay = False}) gs

-- | CR 807.4e / 807.4g: designate a marker for removal this many more times.
-- One whose holder is not taking a turn is removed at once.
designate :: Natural -> Natural -> GameState -> GameState
designate times n gs
  | times == 0 = gs
  | otherwise =
      let marked = overMarker n (\m -> m {TurnMarker.removals = TurnMarker.removals m + times}) gs
       in case markerNumbered n marked of
            Just m | not (TurnMarker.underWay m) -> remove m marked
            _ -> marked

-- | CR 807.4g: remove a marker, the marker to its right inheriting its
-- designations but one. The last marker stays, its designations dropped.
remove :: TurnMarker -> GameState -> GameState
remove marker gs
  | length (GameState.turnMarkers gs) <= 1 = overMarker (TurnMarker.number marker) (\m -> m {TurnMarker.removals = 0}) gs
  | otherwise =
      let removed = gs {GameState.turnMarkers = filter ((/= TurnMarker.number marker) . TurnMarker.number) (GameState.turnMarkers gs)}
       in case nearestRightOf (TurnMarker.holder marker) removed of
            Just right -> designate (TurnMarker.removals marker - min 1 (TurnMarker.removals marker)) (TurnMarker.number right) removed
            Nothing -> removed

-- | The departed seats immediately to `pid`'s right, nearest first, up to the
-- first player still in the game.
departedRightOf :: PlayerId -> GameState -> [PlayerId]
departedRightOf pid gs = takeWhile (`List.notElem` Game.stillPlaying gs) (reverse (seatsLeftOf pid gs))

-- The marker nearest `pid`'s right, `pid`'s own seat looked at last.
nearestRightOf :: PlayerId -> GameState -> Maybe TurnMarker
nearestRightOf pid gs =
  let seats = reverse (seatsLeftOf pid gs) <> [pid]
      heldBy seat = List.find ((== seat) . TurnMarker.holder) (GameState.turnMarkers gs)
   in Maybe.listToMaybe (Maybe.mapMaybe heldBy seats)

-- | CR 807.4c / 807.4e / 807.4f: the markers once these players have left
-- (their statuses already flipped). A marker whose holder left before their
-- turn began goes left at once; one whose holder's turn is under way waits for
-- it to end (passTurn). Each marker the departures cost is designated on the
-- marker nearest a departed seat's right, the lowest-numbered such marker when
-- they name several. Nothing outside the variant.
departed :: [PlayerId] -> GameState -> GameState
departed pids gs
  | not (GameSettings.grandMelee (GameState.settings gs)) || null (GameState.turnMarkers gs) = gs
  | otherwise =
      let -- CR 807.4f: markers already designated are disregarded.
          counted = Natural.minusSaturating (Natural.length (GameState.turnMarkers gs)) (sum (fmap TurnMarker.removals (GameState.turnMarkers gs)))
          cost = Natural.minusSaturating counted (markersFor (Natural.length (Game.stillPlaying gs)))
          candidates = List.sort (fmap TurnMarker.number (Maybe.mapMaybe (`nearestRightOf` gs) pids))
          leaving m = List.elem (TurnMarker.holder m) pids && not (TurnMarker.underWay m)
          moved = List.foldl' (flip passLeft) gs (filter leaving (GameState.turnMarkers gs))
       in case candidates of
            n : _ -> designate cost n moved
            _ -> moved

-- | CR 807.4c / 807.4g / 807.4i: the marker under way once its holder's turn
-- ends, and its number. Removed if designated; kept if its holder's ordinary
-- turn is still to come, or if they have an extra turn pending and no marker
-- within three seats to their right; passed left otherwise.
passTurn :: GameState -> (Maybe Natural, GameState)
passTurn gs = case List.find TurnMarker.underWay (GameState.turnMarkers gs) of
  Nothing -> (Nothing, gs)
  Just marker ->
    let pid = TurnMarker.holder marker
        playing = List.elem pid (Game.stillPlaying gs)
        extra = any ((== pid) . ExtraTurn.taker) (GameState.extraTurns gs)
        keep = overMarker (TurnMarker.number marker) (\m -> m {TurnMarker.underWay = False}) gs
        after
          | TurnMarker.removals marker > 0 = remove marker gs
          | playing && TurnMarker.owesTurn marker = keep
          | playing && extra && not (crowded rightOf marker gs) = keep
          | otherwise = passLeft marker gs
     in (Just (TurnMarker.number marker), after)

-- | CR 807.4d: the marker whose turn begins next -- the first after `ended` in
-- number order whose holder can begin, or failing one the first after it.
nextMarker :: Maybe Natural -> GameState -> Maybe TurnMarker
nextMarker ended gs =
  let (upTo, after) = List.partition (\m -> maybe True (TurnMarker.number m <=) ended) (GameState.turnMarkers gs)
      order = after <> upTo
   in case filter (\m -> not (blocked m gs)) order of
        m : _ -> Just m
        [] -> Maybe.listToMaybe order

-- | CR 807.4i / 807.4j: begin this marker's turn -- its holder's most recently
-- created extra turn if they have one pending, and their ordinary turn under
-- it otherwise.
begin :: TurnMarker -> GameState -> (Maybe ExtraTurn.ExtraTurn, GameState)
begin marker gs =
  let pid = TurnMarker.holder marker
   in case List.find ((== pid) . ExtraTurn.taker) (GameState.extraTurns gs) of
        Just entry ->
          ( Just entry,
            (overMarker (TurnMarker.number marker) (\m -> m {TurnMarker.underWay = True}) gs)
              { GameState.extraTurns = List.delete entry (GameState.extraTurns gs)
              }
          )
        Nothing -> (Nothing, overMarker (TurnMarker.number marker) (\m -> m {TurnMarker.underWay = True, TurnMarker.owesTurn = False}) gs)
