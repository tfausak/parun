-- Instructions (Pawl.Types.Effect) as the sentences Oracle text prints them
-- in, and the clauses, modes and modal payloads that hold them (CR 608.2c,
-- CR 700.2).
module Pawl.Oracle.Effect where

import qualified Control.Monad as Monad
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Pawl.Oracle.Continuous as Continuous
import qualified Pawl.Oracle.Cost as Cost
import qualified Pawl.Oracle.Face as Face.Oracle
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Oracle.Target as Target
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.Clause as Clause
import qualified Pawl.Types.CountedDiscard as CountedDiscard
import qualified Pawl.Types.Counter as Counter
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.CounterName as CounterName
import qualified Pawl.Types.Create as Create
import qualified Pawl.Types.DamageKind as DamageKind
import qualified Pawl.Types.DamagePart as DamagePart
import qualified Pawl.Types.DealDamage as DealDamage
import qualified Pawl.Types.Destroy as Destroy
import qualified Pawl.Types.Discard as Discard
import qualified Pawl.Types.Draw as Draw
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.EachCardInGraveyard as EachCardInGraveyard
import qualified Pawl.Types.Effect as Effect
import qualified Pawl.Types.EntryRiders as EntryRiders
import qualified Pawl.Types.Filter as Filter.Type
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.LibraryPlacement as LibraryPlacement
import qualified Pawl.Types.LibraryPosition as LibraryPosition
import qualified Pawl.Types.LifeLoss as LifeLoss
import qualified Pawl.Types.LifeLossCause as LifeLossCause
import qualified Pawl.Types.ManaAddition as ManaAddition
import qualified Pawl.Types.ManaProduction as ManaProduction
import qualified Pawl.Types.ManaRetention as ManaRetention
import qualified Pawl.Types.Modal as Modal
import qualified Pawl.Types.Mode as Mode
import qualified Pawl.Types.ModeSelection as ModeSelection
import qualified Pawl.Types.Modification as Modification
import qualified Pawl.Types.ModifyTarget as ModifyTarget
import qualified Pawl.Types.MoveToZone as MoveToZone
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.Optionality as Optionality
import qualified Pawl.Types.PlayerQuantity as PlayerQuantity
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.PreventNextDamage as PreventNextDamage
import qualified Pawl.Types.PutCounters as PutCounters
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.RandomCardInHand as RandomCardInHand
import qualified Pawl.Types.Regenerability as Regenerability
import qualified Pawl.Types.SlotCount as SlotCount
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.TapState as TapState
import qualified Pawl.Types.TargetCount as TargetCount
import qualified Pawl.Types.TargetSlot as TargetSlot
import qualified Pawl.Types.TheseDiscard as TheseDiscard
import qualified Pawl.Types.Zone as Zone
import qualified Pawl.Types.ZoneScope as ZoneScope

-- | One instruction as a sentence's parts: who does it (none for an
-- imperative, "Destroy target creature"), the verb phrase agreeing with them,
-- the sentences that must follow it ("It can't be regenerated."), the target
-- slots the verb phrase names, the mana it adds, and whether its subject is a
-- "you" that a sentence of its own leaves out ("Draw a card.") and a sentence
-- joined by "and" keeps ("You draw a card and gain 2 life.").
data Predicate = MkPredicate
  { subject :: Maybe Target.Reference,
    verb :: Text.Text,
    after :: [Text.Text],
    mentions :: [SlotName.SlotName],
    mana :: Maybe Mana,
    implied :: Bool
  }
  deriving (Eq, Show)

-- | Mana an instruction adds: symbols, which a following addition joins
-- ("Add {C}{C}."), or a description, which stands alone ("Add one mana of any
-- color.").
data Mana
  = Symbols Text.Text
  | Described
  deriving (Eq, Show)

-- | A modal payload's text. Only a payload of one mode renders yet; a modal
-- spell's "Choose one" is not spelled out here.
modal :: (Eq ability) => Target.Context -> Modal.Modal Card.Card ability -> [Text.Text]
modal context m = case (Foldable.toList (Modal.modes m), Modal.selection m) of
  ([only], ModeSelection.ChooseExactly 1) -> mode context only
  _ -> []

-- | A mode's sentences, each of its target slots named exactly once (CR
-- 601.2c): a slot named twice, or never, means the text is not the mode's.
-- A spell's sentences are separated as the context's breaks allow.
mode :: (Eq ability) => Target.Context -> Mode.Mode Card.Card ability -> [Text.Text]
mode context m = do
  let inner = context {Target.slots = Mode.targetSlots m}
  rendered <- traverse (clause inner) (Foldable.toList (Mode.clauses m))
  let named = List.sort (concatMap snd rendered)
  Monad.guard (named == Map.keys (Mode.targetSlots m))
  case fmap fst rendered of
    [] -> [Text.empty]
    first : rest -> Monad.foldM (followedBy context) first rest

-- | A clause's sentences and the slots they name: its instructions, or "you
-- may" and the one instruction you may follow (CR 603.5). A clause gated by a
-- condition, an "if you do" or a payment is not spelled out here, nor a "may"
-- another player decides or one over more than one instruction.
clause :: (Eq ability) => Target.Context -> Clause.Clause Card.Card ability -> [(Text.Text, [SlotName.SlotName])]
clause context c
  | Maybe.isJust (Clause.ifTaken c) || Maybe.isJust (Clause.condition c) || Maybe.isJust (Clause.orElse c) || Maybe.isJust (Clause.payGate c) = []
  | otherwise = do
      predicates <- instructions context (Foldable.toList (Clause.effects c))
      case (Clause.optionality c, List.foldr addedTogether [] predicates) of
        (Optionality.Mandatory, together) -> joined context together
        (Optionality.Optional (PlayerRef.Relative PlayerRelation.You), [p])
          | maybe True ((== Text.pack "you") . Target.wording) (subject p) ->
              [(Prose.sentence (Text.pack "you may " <> verb p) <> trailing p, mentions p)]
        _ -> []

-- | A clause's instructions as predicates, consecutive changes to the same
-- objects for the same duration as one: "gets +2/+2 and gains flying until
-- end of turn".
instructions :: (Eq ability) => Target.Context -> [Effect.Effect Card.Card ability] -> [[Predicate]]
instructions context es = case es of
  [] -> [[]]
  Effect.ModifyTarget m : rest
    | Maybe.isNothing (ModifyTarget.each m) -> do
        let alike n = Maybe.isNothing (ModifyTarget.each n) && ModifyTarget.ref n == ModifyTarget.ref m && ModifyTarget.duration n == ModifyTarget.duration m
            (run, others) = span (maybe False alike . modifyTarget) rest
        p <- modified context m (Maybe.mapMaybe (fmap ModifyTarget.modification . modifyTarget) run)
        fmap (p :) (instructions context others)
  e : rest -> do
    p <- effect context e
    fmap (p :) (instructions context rest)

-- | The instruction's continuous effect, if it is one.
modifyTarget :: Effect.Effect card ability -> Maybe (ModifyTarget.ModifyTarget ability)
modifyTarget e = case e of
  Effect.ModifyTarget m -> Just m
  _ -> Nothing

-- | "[Objects] get(s) [change] [duration]": the change an instruction makes to
-- objects for a while (CR 611.2a), and the ones following it to the same
-- objects for the same while.
modified :: Target.Context -> ModifyTarget.ModifyTarget ability -> [Modification.Modification ability] -> [Predicate]
modified context m more = do
  who <- Target.object context Target.Affected (ModifyTarget.ref m)
  let distributed = case ModifyTarget.ref m of
        ObjectRef.InSlot _ -> Target.number who == Filter.Plural
        _ -> False
  (change, defined) <- Continuous.modifications Continuous.Created (Target.number who) distributed context (ModifyTarget.modification m : more)
  lasting <- Continuous.duration (ModifyTarget.duration m)
  case lasting of
    Nothing -> [MkPredicate (Just who) (change <> defined) [] [] Nothing False]
    -- Free: the duration ends the sentence (Giant Growth) or opens it
    -- (Aspirant's Ascent).
    Just period ->
      [ MkPredicate (Just who) (change <> Text.pack " " <> period <> defined) [] [] Nothing False,
        MkPredicate Nothing (period <> Text.pack ", " <> Target.wording who <> Text.pack " " <> change <> defined) [] (Target.mentions who) Nothing False
      ]

-- | One sentence and the next, as the context's breaks allow, or the next
-- opened by "Then", which leaves the card's name capitalised. Free: "Then"
-- (Return of the Nightstalkers) or not (Soul Shred).
followedBy :: Target.Context -> Text.Text -> Text.Text -> [Text.Text]
followedBy context text next =
  let named = Text.isPrefixOf (Target.self context) next
   in [text <> separator <> next | separator <- Target.breaks context] <> [text <> Text.pack " Then " <> (if named then next else Prose.decapitalise next)]

-- | Mana added by consecutive instructions, as Oracle text adds it in one:
-- "Add {C}{C}." (Sol Ring).
addedTogether :: Predicate -> [Predicate] -> [Predicate]
addedTogether p rest = case (mana p, rest) of
  (Just (Symbols a), q : others)
    | Just (Symbols b) <- mana q -> p {verb = Text.pack "add " <> a <> b, mana = Just (Symbols (a <> b))} : others
  _ -> p : rest

-- | The instructions of one clause as Oracle text strings them: one sentence
-- with "and" or two sentences, broken as the context allows. An instruction
-- that adds mana, or that must be followed by a sentence of its own, ends its
-- sentence (Ancient Tomb). An imperative of "you" beside another instruction
-- keeps its "you" when joined to it by "and" (Bad Deal). When two share a
-- subject the second drops it ("draws two cards and loses 2 life"). Three or
-- more are not strung together here yet.
joined :: Target.Context -> [Predicate] -> [(Text.Text, [SlotName.SlotName])]
joined context predicates = case predicates of
  [p] -> [(sentences p, allMentions p)]
  [p, q]
    | not (null (after p)) || Maybe.isJust (mana p) || Maybe.isJust (mana q) -> apart
    -- Free for "you": repeated (Ancient Craving) or not (Ambition's Cost).
    -- Free: "and" (Ancient Craving) or ", then" (Owl Familiar).
    | sameSubject p q ->
        [(Prose.sentence (clauseText p <> Text.pack " and " <> clauseText q) <> trailing q, allMentions p <> allMentions q) | fmap Target.wording (subject q) == Just (Text.pack "you")]
          <> [(Prose.sentence (clauseText p <> Text.pack " and " <> verb q) <> trailing q, allMentions p <> mentions q)]
          <> [(Prose.sentence ((if implied p then verb p else clauseText p) <> Text.pack ", then " <> verb q) <> trailing q, allMentions p <> mentions q)]
    -- Free: two sentences (Afterlife Insurance) or "and" (Bad Deal).
    | implied p || implied q -> apart <> together
    -- Free: "and" (Vampiric Feast) or two sentences (Soul Shred).
    | otherwise -> together <> apart
    where
      together = [(Prose.sentence (clauseText p <> Text.pack " and " <> clauseText q) <> trailing q, allMentions p <> allMentions q)]
      apart = [(text, allMentions p <> allMentions q) | text <- followedBy context (sentences p) (sentences q)]
  _ -> []

-- | Whether two predicates have one subject, so the second can drop it.
sameSubject :: Predicate -> Predicate -> Bool
sameSubject p q = case (subject p, subject q) of
  (Just a, Just b) -> a == b
  _ -> False

-- | The sentences that must follow a predicate, each after a space.
trailing :: Predicate -> Text.Text
trailing p = Text.concat (fmap (Text.pack " " <>) (after p))

-- | The predicate as a sentence of its own, followed by the ones that must
-- follow it.
sentences :: Predicate -> Text.Text
sentences p = Prose.sentence (if implied p then verb p else clauseText p) <> trailing p

-- | The predicate as an independent clause, without a full stop.
clauseText :: Predicate -> Text.Text
clauseText p = case subject p of
  Nothing -> verb p
  Just s -> Target.wording s <> Text.pack " " <> verb p

-- | Every slot the predicate names, its subject's included.
allMentions :: Predicate -> [SlotName.SlotName]
allMentions p = foldMap Target.mentions (subject p) <> mentions p

-- | One instruction's predicate; none for an instruction not spelled out here
-- yet.
effect :: (Eq ability) => Target.Context -> Effect.Effect Card.Card ability -> [Predicate]
effect context e = case e of
  Effect.DealDamage d -> dealDamage context d
  Effect.Draw d
    | Maybe.isNothing (Draw.slot d) -> do
        a <- Target.amounts context (Draw.quantity d)
        count <- case Target.reading a of
          Target.Stated q -> Target.cards q
          -- Free for a count: "a card for each" (Theft of Dreams) or "cards
          -- equal to the number of" (Dream Salvage).
          Target.ForEach n each' -> fmap (<> Text.pack " for each " <> each') (Target.cards (Quantity.Literal n))
          Target.EqualTo equal -> [Text.pack "cards equal to " <> equal]
        naming (Target.names a) (imperative context (Draw.player d) (Text.pack "draw " <> count) (Text.pack "draws " <> count))
  Effect.GainLife g -> do
    a <- Target.amounts context (PlayerQuantity.quantity g)
    n <- life a
    naming (Target.names a) (declarative context (PlayerQuantity.player g) (Text.pack "gain " <> n) (Text.pack "gains " <> n))
  Effect.LoseLife l
    | LifeLoss.cause l == LifeLossCause.ByEffect,
      Maybe.isNothing (LifeLoss.tally l) -> do
        a <- Target.amounts context (LifeLoss.quantity l)
        n <- life a
        naming (Target.names a) (declarative context (LifeLoss.player l) (Text.pack "lose " <> n) (Text.pack "loses " <> n))
  Effect.Destroy d
    | Maybe.isNothing (Destroy.slot d),
      Maybe.isNothing (Destroy.buried d),
      Maybe.isNothing (Destroy.permanents d) -> do
        ref <- Target.object context Target.All (Destroy.ref d)
        let pronoun = case Target.number ref of
              Filter.Singular -> "It"
              Filter.Plural -> "They"
            regenerate = case Destroy.regenerability d of
              Regenerability.Regenerable -> []
              Regenerability.CantBeRegenerated -> [Text.pack (pronoun <> " can't be regenerated.")]
        [MkPredicate Nothing (Text.pack "destroy " <> Target.wording ref) regenerate (Target.mentions ref) Nothing False]
  Effect.Counter c
    | Maybe.isNothing (Counter.slot c),
      Maybe.isNothing (Counter.sources c),
      Maybe.isNothing (Counter.instead c) -> do
        ref <- Target.object context Target.All (Counter.ref c)
        [MkPredicate Nothing (Text.pack "counter " <> Target.wording ref) [] (Target.mentions ref) Nothing False]
  Effect.AddMana a
    | ManaAddition.player a == PlayerRef.Relative PlayerRelation.You,
      ManaAddition.retention a == ManaRetention.Ordinary,
      Maybe.isNothing (ManaAddition.restriction a),
      Maybe.isNothing (ManaAddition.rider a),
      Maybe.isNothing (ManaAddition.whenSpent a) -> do
        amount' <- Target.amounts context (ManaAddition.count a)
        (symbols, phrase) <- case Target.reading amount' of
          Target.Stated q -> added (ManaAddition.production a) q
          -- Mana for each object counted stands alone: "Add {B} for each
          -- Swamp you control." (Cabal Coffers).
          Target.ForEach n each' -> do
            (_, phrase) <- added (ManaAddition.production a) (Quantity.Literal n)
            [(Described, phrase <> Text.pack " for each " <> each')]
          Target.EqualTo _ -> []
        [MkPredicate Nothing (Text.pack "add " <> phrase) [] (Target.names amount') (Just symbols) False]
  Effect.MoveToZone m -> moved context m
  Effect.Create c
    | Create.riders c == EntryRiders.defaultValue -> do
        (one, many) <- Face.Oracle.token (Target.keyword context) (Create.card c)
        a <- Target.amounts context (Create.quantity c)
        let some q = case q of
              Quantity.Literal 1 -> [Prose.article one <> Text.pack " " <> one]
              Quantity.Literal n | n > 1 -> [Prose.cardinal n <> Text.pack " " <> many]
              _ -> []
        tokens <- case Target.reading a of
          Target.Stated q -> some q
          -- Free for a count: "for each" (Endless Swarm) or "a number of"
          -- (Tyranid Invasion).
          Target.ForEach n each' -> fmap (<> Text.pack " for each " <> each') (some (Quantity.Literal n))
          Target.EqualTo equal -> [Text.pack "a number of " <> many <> Text.pack " equal to " <> equal]
        naming (Target.names a) (imperative context (Create.creator c) (Text.pack "create " <> tokens) (Text.pack "creates " <> tokens))
  Effect.PutCounters p -> do
    ref <- Target.object context Target.Each (PutCounters.ref p)
    a <- Target.amounts context (PutCounters.quantity p)
    let on = Text.pack " on " <> Target.wording ref
    phrase <- case Target.reading a of
      -- Free for a count: "for each" (Khabal Ghoul) or "a number of"
      -- (Rhovanion Rampager).
      Target.Stated q -> fmap (\put -> Text.pack "put " <> put <> on) (counters (Target.keyword context) (PutCounters.kind p) q)
      Target.ForEach n each' -> fmap (\put -> Text.pack "put " <> put <> on <> Text.pack " for each " <> each') (counters (Target.keyword context) (PutCounters.kind p) (Quantity.Literal n))
      Target.EqualTo equal -> fmap (\word -> Text.pack "put a number of " <> word <> Text.pack " counters" <> on <> Text.pack " equal to " <> equal) (counterWord (Target.keyword context) (PutCounters.kind p))
    MkPredicate Nothing phrase [] (Target.mentions ref <> Target.names a) Nothing False : supported context p
  Effect.Tap r -> tapped context (Text.pack "tap ") r
  Effect.Untap r -> tapped context (Text.pack "untap ") r
  Effect.Discard d -> discarded context d
  Effect.PreventNextDamage p
    | PreventNextDamage.duration p == Duration.UntilEndOfTurn,
      Maybe.isNothing (PreventNextDamage.whatRecipient p),
      Maybe.isNothing (PreventNextDamage.whoRecipient p),
      Maybe.isNothing (PreventNextDamage.chosenSource p),
      null (PreventNextDamage.riders p),
      Just r <- PreventNextDamage.ref p -> do
        who <- Target.object context Target.Each r
        n <- Target.amount (PreventNextDamage.quantity p)
        let kind = case PreventNextDamage.kind p of
              Nothing -> Text.empty
              Just DamageKind.Combat -> Text.pack "combat "
              Just DamageKind.Noncombat -> Text.pack "noncombat "
        [MkPredicate Nothing (Text.pack "prevent the next " <> n <> Text.pack " " <> kind <> Text.pack "damage that would be dealt to " <> Target.wording who <> Text.pack " this turn") [] (Target.mentions who) Nothing False]
  _ -> []

-- | "[Return/Exile/Put] [objects] [to/into/on] [zone]": a zone change (CR
-- 400.7) as Oracle text words it by where the objects go. A card returns to a
-- hand, and to the battlefield only from your graveyard; any other move is
-- "put", and exiling is its own verb (CR 701.13a). A move with riders other
-- than entering tapped, a move "until" something happens (CR 610.3), or a
-- move onto the battlefield from anywhere else is not spelled out here.
moved :: (Eq ability) => Target.Context -> MoveToZone.MoveToZone ability -> [Predicate]
moved context m
  | Maybe.isJust (MoveToZone.duration m) = []
  | otherwise = do
      let ref = MoveToZone.ref m
          itself = case ref of
            ObjectRef.InSlot s -> s == Target.selfSlot || s == Target.becameSlot
            _ -> False
          graveyard
            | itself && MoveToZone.origin m == Just Zone.Graveyard = Just PlayerRelation.You
            | otherwise = graveyardOf context ref
          yours = graveyard == Just PlayerRelation.You
          riders = MoveToZone.riders m
          plain = riders == EntryRiders.defaultValue
      (who, number) <- case ref of
        -- Free for a description: "all", agreeing in the plural (Evacuation),
        -- or "each", in the singular (Denizen of the Deep).
        ObjectRef.EachMatching _ -> do
          everything <- Target.object context Target.All ref
          single <- Target.object context Target.Each ref
          [(everything, Target.number everything), (single, Filter.Singular)]
        _ -> fmap (\r -> (r, Target.number r)) (Target.object context Target.All ref)
      from <- case MoveToZone.origin m of
        Nothing -> [Text.empty]
        Just Zone.Graveyard
          | itself -> [Text.pack " from your graveyard"]
          | Maybe.isJust graveyard -> [Text.empty]
        _ -> []
      let what = Target.wording who <> from
      phrase <- case MoveToZone.zone m of
        Zone.Hand | plain -> do
          zone <- owner graveyard number (Text.pack "hand")
          [Text.pack "return " <> what <> Text.pack " to " <> zone]
        Zone.Battlefield
          | yours,
            plain || riders == EntryRiders.defaultValue {EntryRiders.tapped = TapState.Tapped} ->
              [Text.pack "return " <> what <> Text.pack " to the battlefield" <> (if plain then Text.empty else Text.pack " tapped")]
        Zone.Exile | plain -> [Text.pack "exile " <> what]
        Zone.Graveyard
          | plain,
            Maybe.isNothing graveyard -> do
              zone <- owner Nothing number (Text.pack "graveyard")
              [Text.pack "put " <> what <> Text.pack " into " <> zone]
        Zone.Library | plain -> do
          zone <- owner graveyard number (Text.pack "library")
          case MoveToZone.placement m of
            LibraryPlacement.Stated LibraryPosition.Top -> [Text.pack "put " <> what <> Text.pack " on top of " <> zone]
            LibraryPlacement.Stated LibraryPosition.Bottom -> [Text.pack "put " <> what <> Text.pack " on the bottom of " <> zone]
            LibraryPlacement.Beneath (Quantity.Literal n) -> do
              place <- Prose.ordinal (n + 1)
              [Text.pack "put " <> what <> Text.pack " into " <> zone <> Text.pack " " <> place <> Text.pack " from the top"]
            _ -> []
        _ -> []
      [MkPredicate Nothing phrase [] (Target.mentions who) Nothing False]

-- | Whose graveyard the cards the reference names are in, if they are in one
-- player's graveyard: yours, or an opponent's.
graveyardOf :: Target.Context -> ObjectRef.ObjectRef -> Maybe PlayerRelation.PlayerRelation
graveyardOf context ref =
  let whose scope = case scope of
        ZoneScope.Scoped (PlayerScope.Related relation)
          | elem relation [PlayerRelation.You, PlayerRelation.Opponent] -> Just relation
        _ -> Nothing
   in case ref of
        ObjectRef.InSlot s -> case fmap TargetSlot.pool (Map.lookup s (Target.slots context)) of
          Just (Pool.CardsInGraveyard scope) -> whose scope
          _ -> Nothing
        ObjectRef.EachCardInGraveyard e -> whose (EachCardInGraveyard.graveyards e)
        _ -> Nothing

-- | A zone of the given objects' owners (CR 400.3): "your hand" for cards from
-- your graveyard, "their hand" for several from an opponent's, and otherwise
-- "its owner's hand" or, for several, "their owners' hands" or "their owner's
-- hand". Free for several: Evacuation's or Retract's.
owner :: Maybe PlayerRelation.PlayerRelation -> Filter.Number -> Text.Text -> [Text.Text]
owner graveyard number zone = case (graveyard, number) of
  (Just PlayerRelation.You, _) -> [Text.pack "your " <> zone]
  (Just PlayerRelation.Opponent, Filter.Plural) -> [Text.pack "their " <> zone]
  (_, Filter.Singular) -> [Text.pack "its owner's " <> zone]
  (_, Filter.Plural) -> [Text.pack "their owners' " <> Filter.pluralOf zone, Text.pack "their owner's " <> zone]

-- | "a +1/+1 counter", "two -1/-1 counters", "a flying counter" (CR 122.1).
counters :: (Keyword.Keyword -> [Text.Text]) -> CounterKind.CounterKind Keyword.Keyword -> Quantity.Quantity -> [Text.Text]
counters named kind q = do
  word <- counterWord named kind
  case q of
    Quantity.Literal 1 -> [Prose.article word <> Text.pack " " <> word <> Text.pack " counter"]
    Quantity.Literal n | n > 1 -> [Prose.cardinal n <> Text.pack " " <> word <> Text.pack " counters"]
    Quantity.InSlot s | s == Target.xSlot -> [Text.pack "X " <> word <> Text.pack " counters"]
    _ -> []

-- | A counter's kind as the word before "counter": "+1/+1", "flying".
counterWord :: (Keyword.Keyword -> [Text.Text]) -> CounterKind.CounterKind Keyword.Keyword -> [Text.Text]
counterWord named kind = case kind of
  CounterKind.PlusOnePlusOne -> [Text.pack "+1/+1"]
  CounterKind.MinusOneMinusOne -> [Text.pack "-1/-1"]
  CounterKind.Keyword k -> named k
  CounterKind.UnsafePowerToughness p t -> do
    power <- Continuous.signed (Quantity.Literal t) (Quantity.Literal p)
    toughness <- Continuous.signed (Quantity.Literal p) (Quantity.Literal t)
    [power <> Text.pack "/" <> toughness]
  CounterKind.Named n -> [CounterName.unwrap n]
  _ -> [Text.toLower (Text.pack (show kind))]

-- | "Support N" (CR 701.41a), the rules' name for putting a +1/+1 counter on
-- each of up to N other target creatures, or on a spell up to N target
-- creatures; a paragraph may break only a spell's instructions (CR 113.3a).
-- Free: the instruction (Travel Preparations) or its name (Lead by Example).
supported :: Target.Context -> PutCounters.PutCounters -> [Predicate]
supported context p = case PutCounters.ref p of
  ObjectRef.InSlot s
    | PutCounters.kind p == CounterKind.PlusOnePlusOne,
      PutCounters.quantity p == Quantity.Literal 1,
      Just slot <- Map.lookup s (Target.slots context),
      TargetSlot.pool slot == Pool.Creatures,
      SlotCount.Printed (TargetCount.MkTargetCount 0 (Just n)) <- TargetSlot.count slot,
      TargetSlot.filter slot == (if elem (Text.pack "\n") (Target.breaks context) then Nothing else Just (Filter.Type.Not Filter.Type.IsSource)),
      Maybe.isNothing (TargetSlot.chooser slot),
      Maybe.isNothing (TargetSlot.perPlayer slot),
      Maybe.isNothing (TargetSlot.together slot),
      Maybe.isNothing (TargetSlot.amount slot),
      Maybe.isNothing (TargetSlot.divided slot) ->
        [MkPredicate Nothing (Text.pack ("support " <> show n)) [] [s] Nothing False]
  _ -> []

-- | "Tap target creature", "Untap all creatures you control".
tapped :: Target.Context -> Text.Text -> ObjectRef.ObjectRef -> [Predicate]
tapped context word r = do
  ref <- Target.object context Target.All r
  [MkPredicate Nothing (word <> Target.wording ref) [] (Target.mentions ref) Nothing False]

-- | "[Player] discards [cards]", of the player's choice or at random (CR
-- 701.9). Cards another player chooses, or a set the instruction names, are
-- not spelled out here.
discarded :: Target.Context -> Discard.Discard -> [Predicate]
discarded context d = case d of
  Discard.Counted c -> do
    n <- Target.cards (CountedDiscard.quantity c)
    imperative context (CountedDiscard.player c) (Text.pack "discard " <> n) (Text.pack "discards " <> n)
  Discard.These t
    | ObjectRef.RandomCardInHand r <- TheseDiscard.cards t,
      RandomCardInHand.filter r == Filter.Type.And [] -> do
        n <- Target.cards (RandomCardInHand.count r)
        let random = n <> Text.pack " at random"
        imperative context (RandomCardInHand.player r) (Text.pack "discard " <> random) (Text.pack "discards " <> random)
  _ -> []

-- | The mana an instruction adds: "{G}", "{C}{C}", "one mana of any color"
-- (CR 106.1).
added :: ManaProduction.ManaProduction -> Quantity.Quantity -> [(Mana, Text.Text)]
added production count = case (production, count) of
  (ManaProduction.OfType t, Quantity.Literal n)
    | n >= 1 ->
        let symbols = Text.concat (List.genericReplicate n (Text.pack "{" <> Cost.manaType t <> Text.pack "}"))
         in [(Symbols symbols, symbols)]
  (ManaProduction.AnyColor, Quantity.Literal 1) -> [(Described, Text.pack "one mana of any color")]
  _ -> []

-- | "[Source] deals [amount] damage to [recipient]", one part after another
-- ("4 damage to any target and 2 damage to you"), or damage divided among a
-- slot's targets (CR 601.2d). Parts naming groups share an amount they share
-- ("X damage to each creature and each player", Earthquake); any other part
-- states its own ("1 damage to any target and 1 damage to you", Brothers of
-- Fire).
dealDamage :: Target.Context -> DealDamage.DealDamage -> [Predicate]
dealDamage context d
  | Maybe.isJust (DealDamage.excess d) = []
  | otherwise = do
      source <- case DealDamage.dealer d of
        Nothing -> [Target.MkReference (Target.self context) [] Filter.Singular]
        Just s -> Target.object context Target.All (ObjectRef.InSlot s)
      -- The source is the sentence's subject, so the amount calls it "it":
      -- "deals damage equal to its power" (Ghitu Fire-Eater).
      let measured = context {Target.self = Text.pack "it"}
      case Foldable.toList (DealDamage.parts d) of
        [DamagePart.MkDamagePart (ObjectRef.InSlot s) (Quantity.Share t)]
          | s == t -> do
              (ref, total) <- Target.among context s
              n <- Target.amount total
              [MkPredicate (Just source) (Text.pack "deals " <> n <> Text.pack " damage divided as you choose among " <> Target.wording ref) [] (Target.mentions ref) Nothing False]
        parts -> do
          let shared = all (each . DamagePart.ref) parts
              groups
                | shared = List.groupBy (\a b -> DamagePart.quantity a == DamagePart.quantity b) parts
                | otherwise = fmap pure parts
          rendered <- traverse (damagePart context measured) groups
          [MkPredicate (Just source) (Text.pack "deals " <> Text.intercalate (Text.pack " and ") (fmap fst rendered)) [] (concatMap snd rendered) Nothing False]

-- | Whether the reference names a group rather than one object or player:
-- "each creature", "each player".
each :: ObjectRef.ObjectRef -> Bool
each ref = case ref of
  ObjectRef.EachMatching _ -> True
  ObjectRef.EachPlayer -> True
  ObjectRef.EachOpponent -> True
  _ -> False

-- | Damage parts sharing an amount: "2 damage to each creature and each
-- player", or damage equal to a number the second context reads. Free:
-- "equal to" after the recipients (Rockslide Ambush) or before them (Soul's
-- Fire), after first for a count and before first for anything else. Damage
-- "for each" object counted is not spelled out here: grep "deals [0-9X]+
-- damage to [^.]* for each" over data/cards, 2026-10-22, finds no count.
damagePart :: Target.Context -> Target.Context -> [DamagePart.DamagePart] -> [(Text.Text, [SlotName.SlotName])]
damagePart context measured group = case group of
  first : _ -> do
    a <- Target.amounts measured (DamagePart.quantity first)
    refs <- traverse (Target.object context Target.Each . DamagePart.ref) group
    let recipients = Prose.listing "and" (fmap Target.wording refs)
        to = Text.pack "damage to " <> recipients
        counted = case DamagePart.quantity first of
          Quantity.Count _ -> True
          _ -> False
    text <- case Target.reading a of
      Target.Stated q -> fmap (<> Text.pack " " <> to) (Target.amount q)
      Target.ForEach _ _ -> []
      Target.EqualTo e ->
        let later = to <> Text.pack " equal to " <> e
            before = Text.pack "damage equal to " <> e <> Text.pack " to " <> recipients
         in if counted then [later, before] else [before, later]
    [(text, concatMap Target.mentions refs <> Target.names a)]
  [] -> []

-- | An amount of life: "4 life", "2 life for each creature you control",
-- "life equal to its power". Free for a count: "for each" (Fruition) or
-- "equal to the number of" (Clearwater Goblet).
life :: Target.Amount -> [Text.Text]
life a = case Target.reading a of
  Target.Stated q -> fmap (<> Text.pack " life") (Target.amount q)
  Target.ForEach n each' -> [Text.pack (show n <> " life for each ") <> each']
  Target.EqualTo e -> [Text.pack "life equal to " <> e]

-- | The predicates with these slots named in them too.
naming :: [SlotName.SlotName] -> [Predicate] -> [Predicate]
naming slots = fmap (\p -> p {mentions = mentions p <> slots})

-- | A player's instruction that Oracle text gives "you" as an imperative
-- when it stands as a sentence of its own ("Draw two cards.").
imperative :: Target.Context -> PlayerRef.PlayerRef -> Text.Text -> Text.Text -> [Predicate]
imperative context ref second third = do
  (who, person) <- Target.player context ref
  case person of
    Target.Second -> [MkPredicate (Just who) second [] [] Nothing True]
    Target.Third -> [MkPredicate (Just who) third [] [] Nothing False]

-- | A player's instruction that always names the player: "You gain 4 life."
declarative :: Target.Context -> PlayerRef.PlayerRef -> Text.Text -> Text.Text -> [Predicate]
declarative context ref second third = do
  (who, person) <- Target.player context ref
  case person of
    Target.Second -> [MkPredicate (Just who) second [] [] Nothing False]
    Target.Third -> [MkPredicate (Just who) third [] [] Nothing False]
