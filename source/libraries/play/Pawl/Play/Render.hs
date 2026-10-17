-- | The text client's drawing of a view: a board summary, then the deciding
-- seat's hand. Reads nothing but the decoded view.
module Pawl.Play.Render where

import qualified Data.Char as Char
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.Codec.GameEvent as Codec.GameEvent
import qualified Pawl.Codec.Reply as Codec.Reply
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.BeginningStep as BeginningStep
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.CombatStep as CombatStep
import qualified Pawl.Types.EndingStep as EndingStep
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Types.Reply as R
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.SeatView as SeatView
import qualified Pawl.Types.TapState as TapState

-- | Seats are numbered from one on screen.
player :: PlayerId.PlayerId -> Text.Text
player pid = Text.pack ("Player " <> show (PlayerId.unwrap pid + 1))

-- | The board summary: whose turn and step, then each seat's totals and
-- permanents, the deciding seat first, then the stack.
board :: PlayerView.PlayerView -> [Text.Text]
board view =
  [ Text.concat
      [ Text.pack ("Turn " <> show (PlayerView.turn view) <> ", "),
        player (PlayerView.active view),
        Text.pack "'s ",
        phase (PlayerView.phase view),
        maybe Text.empty (\p -> Text.pack ". Priority: " <> player p) (PlayerView.priority view),
        Text.pack "."
      ]
  ]
    <> concatMap seat (List.sortOn ((/= PlayerView.viewer view) . SeatView.player) (PlayerView.seats view))
    <> stack
  where
    seat s =
      let pid = SeatView.player s
          you = if pid == PlayerView.viewer view then Text.pack " (you)" else Text.empty
          permanents = filter ((== Just pid) . ObjectView.controller) (PlayerView.battlefield view)
       in [ Text.concat
              [ player pid,
                you,
                Text.pack (": " <> show (SeatView.life s) <> " life, "),
                count (SeatView.handSize s) "card" <> Text.pack " in hand, ",
                Text.pack (show (SeatView.librarySize s) <> " in library")
              ]
          ]
            <> listed "  Battlefield: " permanents
            <> listed "  Graveyard: " (SeatView.graveyard s)
            <> listed "  Exile: " (SeatView.exile s)
    stack = listed "Stack, top first: " (PlayerView.stack view)

-- | The deciding seat's hand.
hand :: PlayerView.PlayerView -> [Text.Text]
hand view =
  let held = concatMap SeatView.hand (filter ((== PlayerView.viewer view) . SeatView.player) (PlayerView.seats view))
   in [Text.pack "Your hand: " <> if null held then Text.pack "empty" else Text.intercalate (Text.pack ", ") (fmap describe held)]

listed :: String -> [ObjectView.ObjectView] -> [Text.Text]
listed label shown = [Text.pack label <> Text.intercalate (Text.pack ", ") (fmap describe shown) | not (null shown)]

-- | An object's name, power and toughness, and status.
describe :: ObjectView.ObjectView -> Text.Text
describe o =
  let pt = do
        c <- ObjectView.characteristics o
        p <- ProjectedCharacteristics.power c
        t <- ProjectedCharacteristics.toughness c
        pure (Text.pack (" " <> show p <> "/" <> show t))
      status =
        [Text.pack "tapped" | ObjectView.tapped o == TapState.Tapped]
          <> [Text.pack (show (ObjectView.damage o) <> " damage") | ObjectView.damage o > 0]
          <> [count (sum (ObjectView.counters o)) "counter" | not (Map.null (ObjectView.counters o))]
   in nameOf o <> Maybe.fromMaybe Text.empty pt <> if null status then Text.empty else Text.pack " (" <> Text.intercalate (Text.pack ", ") status <> Text.pack ")"

-- | CR 708.2a: a face-down object has no name, and a hidden one shows none.
nameOf :: ObjectView.ObjectView -> Text.Text
nameOf o = case ObjectView.characteristics o of
  Nothing -> Text.pack "a hidden card"
  Just c -> case Set.toList (ProjectedCharacteristics.names c) of
    [] -> Text.pack "a face-down card"
    names -> Text.intercalate (Text.pack " // ") (fmap CardName.unwrap names)

-- | Every object the view shows, by id.
objects :: PlayerView.PlayerView -> Map.Map ObjectId.ObjectId ObjectView.ObjectView
objects view =
  Map.fromList . fmap (\o -> (ObjectView.object o, o)) $
    PlayerView.battlefield view
      <> PlayerView.stack view
      <> concatMap (\s -> SeatView.hand s <> SeatView.library s <> SeatView.graveyard s <> SeatView.exile s) (PlayerView.seats view)

-- | An object by id, named as the view shows it.
named :: PlayerView.PlayerView -> ObjectId.ObjectId -> Text.Text
named view oid = maybe (Text.pack ("object " <> show (ObjectId.unwrap oid))) nameOf (Map.lookup oid (objects view))

-- | A witnessed event, by its kind.
--
-- Not implemented: the cards, players and amounts an event names (#5229).
event :: LoggedEvent.LoggedEvent -> Text.Text
event logged = case Codec.Reply.fromValue (Codec.encode Codec.GameEvent.codec (LoggedEvent.event logged)) of
  Right (R.Object pairs) | Just (R.Text kind) <- List.lookup (Text.pack "type") pairs -> spaced kind
  _ -> Text.pack "something happened"

result :: Result.Result -> Text.Text
result r = case r of
  Result.Won pid -> player pid <> Text.pack " wins."
  Result.TeamWon _ -> Text.pack "A team wins."
  Result.Drawn -> Text.pack "The game is a draw."

phase :: Phase.Phase -> Text.Text
phase p = Text.pack $ case p of
  Phase.Beginning step -> case step of
    BeginningStep.Untap -> "untap step"
    BeginningStep.Upkeep -> "upkeep"
    BeginningStep.DrawStep -> "draw step"
  Phase.PrecombatMain -> "precombat main phase"
  Phase.Combat step -> case step of
    CombatStep.BeginningOfCombat -> "beginning of combat"
    CombatStep.DeclareAttackers -> "declare attackers step"
    CombatStep.DeclareBlockers -> "declare blockers step"
    CombatStep.CombatDamage -> "combat damage step"
    CombatStep.EndOfCombat -> "end of combat"
  Phase.PostcombatMain -> "postcombat main phase"
  Phase.Ending step -> case step of
    EndingStep.EndStep -> "end step"
    EndingStep.Cleanup -> "cleanup step"

count :: Natural -> String -> Text.Text
count n noun = Text.pack (show n <> " " <> noun <> if n == 1 then "" else "s")

-- | "SpellCast" as "spell cast".
spaced :: Text.Text -> Text.Text
spaced = Text.strip . Text.toLower . Text.concatMap (\c -> if Char.isUpper c then Text.pack [' ', c] else Text.singleton c)
