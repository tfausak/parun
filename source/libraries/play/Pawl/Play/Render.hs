-- | The text client's drawing of a view: a board summary, then the deciding
-- seat's hand. Reads nothing but the decoded view.
module Pawl.Play.Render where

import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Pawl.Codec.GameEvent as Codec.GameEvent
import qualified Pawl.Codec.Reply as Codec.Reply
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.AttackTarget as AttackTarget
import qualified Pawl.Types.AttackerDeclared as AttackerDeclared
import qualified Pawl.Types.BecameBlocking as BecameBlocking
import qualified Pawl.Types.BeginningStep as BeginningStep
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.CombatStep as CombatStep
import qualified Pawl.Types.Countering as Countering
import qualified Pawl.Types.DamageEvent as DamageEvent
import qualified Pawl.Types.Discarded as Discarded
import qualified Pawl.Types.Drew as Drew
import qualified Pawl.Types.EndingStep as EndingStep
import qualified Pawl.Types.GameEvent as GameEvent
import qualified Pawl.Types.LandPlayed as LandPlayed
import qualified Pawl.Types.LifeChange as LifeChange
import qualified Pawl.Types.LoggedEvent as LoggedEvent
import qualified Pawl.Types.Looked as Looked
import qualified Pawl.Types.Milled as Milled
import qualified Pawl.Types.Moved as Moved
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.Phase as Phase
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.PlayerView as PlayerView
import qualified Pawl.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Types.Recipient as Recipient
import qualified Pawl.Types.Reply as R
import qualified Pawl.Types.Result as Result
import qualified Pawl.Types.Revealed as Revealed
import qualified Pawl.Types.SeatView as SeatView
import qualified Pawl.Types.SpellWasCast as SpellWasCast
import qualified Pawl.Types.TapState as TapState
import qualified Pawl.Types.Transformed as Transformed
import qualified Pawl.Types.Zone as Zone
import qualified Pawl.Types.ZoneChange as ZoneChange

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

-- | CR 708.2a: a face-down object has no name, and a hidden one shows none;
-- CR 406.3 / 708.5: a face-down card the seat may look at names its card too.
nameOf :: ObjectView.ObjectView -> Text.Text
nameOf o =
  let shown = case ObjectView.characteristics o of
        Nothing | Maybe.isNothing (ObjectView.face o) -> Text.pack "a hidden card"
        Just c | names <- Set.toList (ProjectedCharacteristics.names c), not (null names) -> joined names
        _ -> Text.pack "a face-down card"
      joined = Text.intercalate (Text.pack " // ") . fmap CardName.unwrap
      card = foldMap (\f -> Text.pack " (" <> joined (Set.toList (ProjectedCharacteristics.names f)) <> Text.pack ")") (ObjectView.face o)
   in shown <> card

-- | Every object the view shows, by id.
objects :: PlayerView.PlayerView -> Map.Map ObjectId.ObjectId ObjectView.ObjectView
objects view =
  Map.fromList . fmap (\o -> (ObjectView.object o, o)) $
    PlayerView.battlefield view
      <> PlayerView.stack view
      <> concatMap (\s -> SeatView.hand s <> SeatView.library s <> SeatView.graveyard s <> SeatView.exile s) (PlayerView.seats view)

-- | An object by id, named as the view shows it, or else as the last witnessed
-- entry that named it showed it, so one that has since left still has a name.
named :: PlayerView.PlayerView -> ObjectId.ObjectId -> Text.Text
named view oid = case Map.lookup oid (objects view) of
  Just o -> nameOf o
  Nothing -> maybe (Text.pack ("object " <> show (ObjectId.unwrap oid))) snapshotName (Map.lookup oid (snapshots view))

-- | The characteristics each witnessed entry showed an object with, by id, the
-- latest winning.
snapshots :: PlayerView.PlayerView -> Map.Map ObjectId.ObjectId ProjectedCharacteristics.ProjectedCharacteristics
snapshots view =
  Map.fromList . concatMap (shownBy . LoggedEvent.event) $ PlayerView.witnessed view
  where
    shownBy e = case e of
      GameEvent.Moved m -> fmap (\oid -> (oid, Moved.characteristics m)) (ZoneChange.departed (Moved.change m) : ZoneChange.object (Moved.change m) : Foldable.toList (Moved.otherArrivals m))
      GameEvent.SpellCast c -> [(SpellWasCast.spell c, SpellWasCast.characteristics c)]
      GameEvent.Revealed r -> [(Revealed.card r, Revealed.characteristics r)]
      GameEvent.Looked l -> [(Looked.card l, Looked.characteristics l)]
      GameEvent.Transformed t -> [(Transformed.object t, Transformed.characteristics t)]
      _ -> []

-- | CR 708.2a: a face-down object has no name.
snapshotName :: ProjectedCharacteristics.ProjectedCharacteristics -> Text.Text
snapshotName c = case Set.toList (ProjectedCharacteristics.names c) of
  [] -> Text.pack "a face-down card"
  names -> Text.intercalate (Text.pack " // ") (fmap CardName.unwrap names)

-- | A witnessed entry as a sentence naming its cards, players and amounts, or
-- nothing for the bookkeeping a seat can read off the board (a step, a tap,
-- mana, a trigger) or another entry already tells (a spell's own move, a
-- discard's or mill's move, a block's per-attacker records).
event :: PlayerView.PlayerView -> LoggedEvent.LoggedEvent -> Maybe Text.Text
event view logged = case LoggedEvent.event logged of
  GameEvent.SpellCast c -> said [player (SpellWasCast.player c), Text.pack "casts", snapshotName (SpellWasCast.characteristics c)]
  GameEvent.LandPlayed l -> said [player (LandPlayed.player l), Text.pack "plays", name (LandPlayed.land l)]
  GameEvent.AttackerDeclared a -> said [name (AttackerDeclared.attacker a), Text.pack "attacks", attacked (AttackerDeclared.target a)]
  GameEvent.BecameBlocking b -> said [name (BecameBlocking.blocker b), Text.pack "blocks", name (BecameBlocking.attacker b)]
  GameEvent.DamageDealt d -> said [name (DamageEvent.source d), Text.pack "deals", Text.pack (show (DamageEvent.amount d)), Text.pack "damage to", recipient (DamageEvent.target d)]
  GameEvent.LifeLost l -> said [player (LifeChange.player l), Text.pack "loses", Text.pack (show (LifeChange.amount l)), Text.pack "life"]
  GameEvent.LifeGained l -> said [player (LifeChange.player l), Text.pack "gains", Text.pack (show (LifeChange.amount l)), Text.pack "life"]
  GameEvent.Moved m
    | from `elem` [Zone.Stack, Zone.Hand, Zone.Library] -> Nothing
    | to == Zone.Graveyard -> said [snapshotName (Moved.characteristics m), Text.pack "is put into a graveyard from", zone from]
    | otherwise -> said [snapshotName (Moved.characteristics m), Text.pack "moves from", zone from, Text.pack "to", zone to]
    where
      from = ZoneChange.from (Moved.change m)
      to = ZoneChange.to (Moved.change m)
  GameEvent.Discarded d -> said [player (Discarded.player d), Text.pack "discards", name (Discarded.card d)]
  GameEvent.Milled m -> said [player (Milled.player m), Text.pack "mills", Text.intercalate (Text.pack ", ") (fmap name (Foldable.toList (Milled.cards m)))]
  GameEvent.Drew d -> said [player (Drew.player d), Text.pack "draws a card"]
  GameEvent.Revealed r -> said [player (Revealed.player r), Text.pack "reveals", snapshotName (Revealed.characteristics r)]
  GameEvent.Looked l -> said [Text.pack "Looked at", snapshotName (Looked.characteristics l)]
  GameEvent.SpellCountered c -> said [name (Countering.countered c), Text.pack "is countered"]
  GameEvent.StepBegan {} -> Nothing
  GameEvent.CardArrived {} -> Nothing
  GameEvent.AttackersDeclared {} -> Nothing
  GameEvent.BecameAttacked {} -> Nothing
  GameEvent.AttackerBlocked {} -> Nothing
  GameEvent.AttackerUnblocked {} -> Nothing
  GameEvent.BlocksDeclared {} -> Nothing
  GameEvent.BecameTapped {} -> Nothing
  GameEvent.BecameUntapped {} -> Nothing
  GameEvent.TappedForMana {} -> Nothing
  GameEvent.ManaAdded {} -> Nothing
  GameEvent.ManaAbilityResolved {} -> Nothing
  GameEvent.AbilityTriggered {} -> Nothing
  GameEvent.ActivatedAbilityResolved {} -> Nothing
  GameEvent.TriggeredAbilityResolved {} -> Nothing
  GameEvent.BecameTarget {} -> Nothing
  GameEvent.PermanentActed {} -> Nothing
  GameEvent.PlayerActed {} -> Nothing
  other -> Just (kindOf other)
  where
    name = named view
    said parts = Just (Text.unwords parts <> Text.pack ".")
    attacked target = case target of
      AttackTarget.OfPlayer pid -> player pid
      AttackTarget.OfPlaneswalker oid -> name oid
      AttackTarget.OfBattle oid -> name oid
    recipient r = case r of
      Recipient.ToPlayer pid -> player pid
      Recipient.ToCreature oid -> name oid
      Recipient.ToPlaneswalker oid -> name oid
      Recipient.ToBattle oid -> name oid
      Recipient.ToObject oid -> name oid
      Recipient.ToPile _ -> Text.pack "a pile"

-- | An entry by its kind: "SpellCast" as "spell cast".
kindOf :: GameEvent.GameEvent -> Text.Text
kindOf e = case Codec.Reply.fromValue (Codec.encode Codec.GameEvent.codec e) of
  Right (R.Object pairs) | Just (R.Text kind) <- List.lookup (Text.pack "type") pairs -> spaced kind
  _ -> Text.pack "something happened"

zone :: Zone.Zone -> Text.Text
zone z = Text.pack $ case z of
  Zone.Library -> "a library"
  Zone.Hand -> "a hand"
  Zone.Graveyard -> "a graveyard"
  Zone.Battlefield -> "the battlefield"
  Zone.Stack -> "the stack"
  Zone.Exile -> "exile"
  Zone.Command -> "the command zone"
  Zone.Ante -> "the ante"

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
