-- | The text client's drawing of a view: a board summary, then the deciding
-- seat's hand. Reads nothing but the decoded view, and a card's printed text
-- by a name the view shows.
module Parun.Play.Render where

import qualified Data.Char as Char
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import Numeric.Natural (Natural)
import qualified Parun.Codec.GameEvent as Codec.GameEvent
import qualified Parun.Codec.Reply as Codec.Reply
import qualified Parun.Exceptions.InvalidCorpus as InvalidCorpus
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AbilityView as AbilityView
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.AttackerDeclared as AttackerDeclared
import qualified Parun.Types.BecameBlocking as BecameBlocking
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Countering as Countering
import qualified Parun.Types.DamageEvent as DamageEvent
import qualified Parun.Types.Defense as Defense
import qualified Parun.Types.Discarded as Discarded
import qualified Parun.Types.Drew as Drew
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Face as Face
import qualified Parun.Types.GameEvent as GameEvent
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.HybridPhyrexian as HybridPhyrexian
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.LandPlayed as LandPlayed
import qualified Parun.Types.LifeChange as LifeChange
import qualified Parun.Types.LoggedEvent as LoggedEvent
import qualified Parun.Types.Looked as Looked
import qualified Parun.Types.Loyalty as Loyalty
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Milled as Milled
import qualified Parun.Types.Moved as Moved
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectView as ObjectView
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PlayerView as PlayerView
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Types.Recipient as Recipient
import qualified Parun.Types.Reply as R
import qualified Parun.Types.Result as Result
import qualified Parun.Types.Revealed as Revealed
import qualified Parun.Types.SeatView as SeatView
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneChange as ZoneChange

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
          (lands, rest) = List.partition (isA CardType.Land) (filter ((== Just pid) . ObjectView.controller) (PlayerView.battlefield view))
          (creatures, others) = List.partition (isA CardType.Creature) rest
       in [ Text.concat
              [ player pid,
                you,
                Text.pack (": " <> show (SeatView.life s) <> " life, "),
                count (SeatView.handSize s) "card" <> Text.pack " in hand, ",
                Text.pack (show (SeatView.librarySize s) <> " in library")
              ]
          ]
            <> listed view "  Lands: " (ordered view lands)
            <> listed view "  Creatures: " (ordered view creatures)
            <> listed view "  Other permanents: " (ordered view others)
            <> listed view "  Graveyard: " (SeatView.graveyard s)
            <> listed view "  Exile: " (SeatView.exile s)
    stack = listed view "Stack, top first: " (PlayerView.stack view)

-- | The deciding seat's hand.
hand :: PlayerView.PlayerView -> [Text.Text]
hand view =
  let held = concatMap SeatView.hand (filter ((== PlayerView.viewer view) . SeatView.player) (PlayerView.seats view))
      (lands, spells) = List.partition (isA CardType.Land) held
   in [Text.pack "Your hand: " <> if null held then Text.pack "empty" else Text.intercalate (Text.pack ", ") (fmap (describe view) (ordered view lands <> ordered view spells))]

-- | Whether the seat sees the object as having a card type.
isA :: CardType.CardType -> ObjectView.ObjectView -> Bool
isA t = maybe False (Set.member t . ProjectedCharacteristics.cardTypes) . ObjectView.characteristics

-- | By mana value, then name, ties in the view's order.
ordered :: PlayerView.PlayerView -> [ObjectView.ObjectView] -> [ObjectView.ObjectView]
ordered view = List.sortOn (\o -> (Maybe.fromMaybe 0 (ObjectView.characteristics o >>= ProjectedCharacteristics.manaValue), Text.toLower (nameOf view o)))

listed :: PlayerView.PlayerView -> String -> [ObjectView.ObjectView] -> [Text.Text]
listed view label shown = [Text.pack label <> Text.intercalate (Text.pack ", ") (fmap (describe view) shown) | not (null shown)]

-- | An object's name, power and toughness, and status.
describe :: PlayerView.PlayerView -> ObjectView.ObjectView -> Text.Text
describe view o =
  let pt = do
        c <- ObjectView.characteristics o
        p <- ProjectedCharacteristics.power c
        t <- ProjectedCharacteristics.toughness c
        pure (Text.pack (" " <> show p <> "/" <> show t))
      status =
        [Text.pack "tapped" | ObjectView.tapped o == TapState.Tapped]
          <> [Text.pack (show (ObjectView.damage o) <> " damage") | ObjectView.damage o > 0]
          <> [count (sum (ObjectView.counters o)) "counter" | not (Map.null (ObjectView.counters o))]
   in nameOf view o <> Maybe.fromMaybe Text.empty pt <> if null status then Text.empty else Text.pack " (" <> Text.intercalate (Text.pack ", ") status <> Text.pack ")"

-- | CR 708.2a: a face-down object has no name, and a hidden one shows none;
-- CR 406.3 / 708.5: a face-down card the seat may look at names its card too.
-- CR 113.7a / 602.2a: an ability has no name, so it is named by its source.
nameOf :: PlayerView.PlayerView -> ObjectView.ObjectView -> Text.Text
nameOf view o = case ObjectView.ability o of
  Just a -> maybe (Text.pack "an ability") (<> Text.pack "'s ability") (AbilityView.source a >>= knownName view)
  Nothing -> cardName o

-- | A card's name as the seat sees it.
cardName :: ObjectView.ObjectView -> Text.Text
cardName o =
  let shown = case ObjectView.characteristics o of
        Nothing | Maybe.isNothing (ObjectView.face o) -> Text.pack "a hidden card"
        Just c | names <- Set.toList (ProjectedCharacteristics.names c), not (null names) -> joined names
        _ -> Text.pack "a face-down card"
      joined = Text.intercalate (Text.pack " // ") . fmap CardName.unwrap
      card = foldMap (\f -> Text.pack " (" <> joined (Set.toList (ProjectedCharacteristics.names f)) <> Text.pack ")") (ObjectView.face o)
   in shown <> card

-- | The names a seat may read an object's card by: the card behind a face-down
-- object it may look at (CR 708.5), else the object's own, which a face-down
-- one has none of (CR 708.2a).
cardNames :: ObjectView.ObjectView -> Set.Set CardName.CardName
cardNames o = maybe (foldMap ProjectedCharacteristics.names (ObjectView.characteristics o)) ProjectedCharacteristics.names (ObjectView.face o)

-- | An object in full, as the seat sees it: its summary, its characteristics
-- now, the card behind it when face down and the seat may look, its
-- counters, and the printed Oracle text of the faces it is named for; or why
-- the card data could not say.
details :: (CardName.CardName -> Either InvalidCorpus.InvalidCorpus (Maybe Card.Card)) -> PlayerView.PlayerView -> ObjectView.ObjectView -> Either InvalidCorpus.InvalidCorpus [Text.Text]
details lookUp view o = do
  looked <- traverse lookUp (Set.toList names)
  let faces = concatMap (filter ((`Set.member` names) . Face.name) . Foldable.toList . Card.faces) (ListUtils.nubOrd (Maybe.catMaybes looked))
      oracle f = [CardName.unwrap (Face.name f) <> Text.pack ":" | length faces > 1] <> foldMap Text.lines (Face.oracleText f)
  pure $
    [describe view o]
      <> foldMap characteristicLines (ObjectView.characteristics o)
      <> foldMap (\f -> Text.pack "Face down. You may look at it:" : characteristicLines f) (ObjectView.face o)
      <> [Text.pack "Counters: " <> Text.intercalate (Text.pack ", ") (fmap counted (Map.toList (ObjectView.counters o))) | not (Map.null (ObjectView.counters o))]
      <> foldMap oracle faces
  where
    names = cardNames o
    counted (kind, n) = Text.pack (show n <> " ") <> counterName kind

-- | CR 201.1 / 202.1 / 205.1 / 208.1: the name line with its mana cost, the type line, and
-- power and toughness, loyalty or defense.
characteristicLines :: ProjectedCharacteristics.ProjectedCharacteristics -> [Text.Text]
characteristicLines c =
  [Text.unwords (title <> foldMap (pure . manaCost) (ProjectedCharacteristics.manaCost c)) | not (null title) || Maybe.isJust (ProjectedCharacteristics.manaCost c)]
    <> [Text.unwords (supertypes <> types <> if null subtypes then [] else Text.pack "\8212" : subtypes)]
    <> foldMap (\(p, t) -> [Text.pack (show p <> "/" <> show t)]) ((,) <$> ProjectedCharacteristics.power c <*> ProjectedCharacteristics.toughness c)
    <> foldMap (\l -> [Text.pack "Loyalty " <> loyalty l]) (ProjectedCharacteristics.loyalty c)
    <> foldMap (\d -> [Text.pack ("Defense " <> show (Defense.unwrap d))]) (ProjectedCharacteristics.defense c)
  where
    title = [Text.intercalate (Text.pack " // ") (fmap CardName.unwrap (Set.toList (ProjectedCharacteristics.names c))) | not (Set.null (ProjectedCharacteristics.names c))]
    supertypes = fmap (Text.pack . show) (Set.toList (ProjectedCharacteristics.supertypes c))
    types = fmap (Text.pack . show) (Set.toList (ProjectedCharacteristics.cardTypes c))
    subtypes = fmap (Text.pack . show) (Set.toList (ProjectedCharacteristics.subtypes c))
    loyalty l = case l of
      Loyalty.Literal n -> Text.pack (show n)
      Loyalty.Variable -> Text.pack "X"

-- | CR 122.1: a counter's kind as a player says it.
counterName :: CounterKind.CounterKind Keyword.Keyword -> Text.Text
counterName kind = case kind of
  CounterKind.PlusOnePlusOne -> Text.pack "+1/+1"
  CounterKind.MinusOneMinusOne -> Text.pack "-1/-1"
  other -> Text.unwords (Text.words (spaced (Text.pack (show other))))

-- | CR 107.4's symbols as the cost is printed.
manaCost :: ManaCost.ManaCost -> Text.Text
manaCost cost = case ManaCost.unwrap cost of
  [] -> Text.pack "{0}"
  symbols -> foldMap symbol symbols
  where
    symbol s = Text.pack "{" <> inside s <> Text.pack "}"
    inside s = case s of
      ManaSymbol.Generic n -> Text.pack (show n)
      ManaSymbol.OfType t -> manaType t
      ManaSymbol.Hybrid h -> manaType (Hybrid.left h) <> Text.pack "/" <> manaType (Hybrid.right h)
      ManaSymbol.MonocoloredHybrid t -> Text.pack "2/" <> manaType t
      ManaSymbol.Phyrexian c -> manaType (ManaType.Colored c) <> Text.pack "/P"
      ManaSymbol.HybridPhyrexian h -> manaType (ManaType.Colored (HybridPhyrexian.left h)) <> Text.pack "/" <> manaType (ManaType.Colored (HybridPhyrexian.right h)) <> Text.pack "/P"
      ManaSymbol.Snow -> Text.pack "S"
      ManaSymbol.Variable -> Text.pack "X"

-- | CR 107.4: a mana type's symbol letter.
manaType :: ManaType.ManaType -> Text.Text
manaType t = Text.pack $ case t of
  ManaType.Colored Color.White -> "W"
  ManaType.Colored Color.Blue -> "U"
  ManaType.Colored Color.Black -> "B"
  ManaType.Colored Color.Red -> "R"
  ManaType.Colored Color.Green -> "G"
  ManaType.Colorless -> "C"

-- | Every object the view shows, by id.
objects :: PlayerView.PlayerView -> Map.Map ObjectId.ObjectId ObjectView.ObjectView
objects view =
  Map.fromList . fmap (\o -> (ObjectView.object o, o)) $
    PlayerView.battlefield view
      <> PlayerView.stack view
      <> concatMap (\s -> SeatView.hand s <> SeatView.library s <> SeatView.graveyard s <> SeatView.exile s) (PlayerView.seats view)

-- | An object by id, named as the view shows it, or else as the last witnessed
-- move of it showed it, so one that has since left still has a name.
named :: PlayerView.PlayerView -> ObjectId.ObjectId -> Text.Text
named view oid = Maybe.fromMaybe (Text.pack ("object " <> show (ObjectId.unwrap oid))) (knownName view oid)

-- | An object's name, if the view shows it or a witnessed move of it.
knownName :: PlayerView.PlayerView -> ObjectId.ObjectId -> Maybe Text.Text
knownName view oid = case Map.lookup oid (objects view) of
  Just o -> Just (nameOf view o)
  Nothing -> fmap snapshotName (Map.lookup oid (snapshots view))

-- | What each witnessed move showed the object it moved as, by
-- either end's id, the latest winning.
snapshots :: PlayerView.PlayerView -> Map.Map ObjectId.ObjectId ProjectedCharacteristics.ProjectedCharacteristics
snapshots view =
  Map.fromList
    [ (oid, Moved.characteristics m)
    | GameEvent.Moved m <- fmap LoggedEvent.event (witnessed view),
      oid <- ZoneChange.departed (Moved.change m) : Foldable.toList (Moved.arrivals m)
    ]

-- | The entries the view says the seat witnessed, last turn's and this
-- turn's, oldest first.
witnessed :: PlayerView.PlayerView -> [LoggedEvent.LoggedEvent]
witnessed view = PlayerView.witnessedLastTurn view <> PlayerView.witnessed view

-- | CR 708.2a: a face-down object has no name.
snapshotName :: ProjectedCharacteristics.ProjectedCharacteristics -> Text.Text
snapshotName c = case Set.toList (ProjectedCharacteristics.names c) of
  [] -> Text.pack "a face-down card"
  names -> Text.intercalate (Text.pack " // ") (fmap CardName.unwrap names)

-- | Witnessed entries as sentences, a run of one player's draws told as one.
events :: PlayerView.PlayerView -> [LoggedEvent.LoggedEvent] -> [Text.Text]
events view = concatMap sentences . List.groupBy (\a b -> Maybe.isJust (drawer a) && drawer a == drawer b) . filter (Maybe.isJust . event view)
  where
    drawer logged = case LoggedEvent.event logged of
      GameEvent.Drew d -> Just (Drew.player d)
      _ -> Nothing
    sentences run = case run of
      first : _ : _ | Just pid <- drawer first -> [player pid <> Text.pack " draws " <> count (List.genericLength run) "card" <> Text.pack "."]
      _ -> Maybe.mapMaybe (event view) run

-- | A witnessed entry as a sentence naming its cards, players and amounts, or
-- nothing for the bookkeeping a seat can read off the board (a step, a tap,
-- mana, a trigger) or another entry already tells (a cast's, land play's,
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
    | any (`Set.member` told view) (Moved.arrivals m) -> Nothing
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

-- | The objects whose arrival another witnessed entry already tells: a spell
-- cast, a land played, a card discarded or milled. Only the move that made
-- one is told; a later move of it is not.
told :: PlayerView.PlayerView -> Set.Set ObjectId.ObjectId
told view =
  Set.fromList . concatMap (telling . LoggedEvent.event) $ witnessed view
  where
    telling e = case e of
      GameEvent.SpellCast c -> [SpellWasCast.spell c]
      GameEvent.LandPlayed l -> [LandPlayed.land l]
      GameEvent.Discarded d -> [Discarded.card d]
      GameEvent.Milled m -> Foldable.toList (Milled.cards m)
      _ -> []

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
