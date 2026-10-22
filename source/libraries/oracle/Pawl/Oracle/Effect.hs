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
import qualified Pawl.Oracle.Filter as Filter
import qualified Pawl.Oracle.Prose as Prose
import qualified Pawl.Oracle.Target as Target
import qualified Pawl.Types.Clause as Clause
import qualified Pawl.Types.Counter as Counter
import qualified Pawl.Types.DamagePart as DamagePart
import qualified Pawl.Types.DealDamage as DealDamage
import qualified Pawl.Types.Destroy as Destroy
import qualified Pawl.Types.Draw as Draw
import qualified Pawl.Types.Effect as Effect
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
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.Optionality as Optionality
import qualified Pawl.Types.PlayerQuantity as PlayerQuantity
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.Regenerability as Regenerability
import qualified Pawl.Types.SlotName as SlotName

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
modal :: Target.Context -> Modal.Modal card ability -> [Text.Text]
modal context m = case (Foldable.toList (Modal.modes m), Modal.selection m) of
  ([only], ModeSelection.ChooseExactly 1) -> mode context only
  _ -> []

-- | A mode's sentences, each of its target slots named exactly once (CR
-- 601.2c): a slot named twice, or never, means the text is not the mode's.
-- A spell's sentences are separated as the context's breaks allow.
mode :: Target.Context -> Mode.Mode card ability -> [Text.Text]
mode context m = do
  let inner = context {Target.slots = Mode.targetSlots m}
  rendered <- traverse (clause inner) (Foldable.toList (Mode.clauses m))
  let named = List.sort (concatMap snd rendered)
  Monad.guard (named == Map.keys (Mode.targetSlots m))
  case fmap fst rendered of
    [] -> [Text.empty]
    first : rest -> Monad.foldM (\text next -> fmap (\separator -> text <> separator <> next) (Target.breaks context)) first rest

-- | A clause's sentences and the slots they name: its instructions, or "you
-- may" and the one instruction you may follow (CR 603.5). A clause gated by a
-- condition, an "if you do" or a payment is not spelled out here, nor a "may"
-- another player decides or one over more than one instruction.
clause :: Target.Context -> Clause.Clause card ability -> [(Text.Text, [SlotName.SlotName])]
clause context c
  | Maybe.isJust (Clause.ifTaken c) || Maybe.isJust (Clause.condition c) || Maybe.isJust (Clause.orElse c) || Maybe.isJust (Clause.payGate c) = []
  | otherwise = do
      predicates <- instructions context (Foldable.toList (Clause.effects c))
      case (Clause.optionality c, List.foldr addedTogether [] predicates) of
        (Optionality.Mandatory, together) -> joined (Target.breaks context) together
        (Optionality.Optional (PlayerRef.Relative PlayerRelation.You), [p])
          | maybe True ((== Text.pack "you") . Target.wording) (subject p) ->
              [(Prose.sentence (Text.pack "you may " <> verb p) <> trailing p, mentions p)]
        _ -> []

-- | A clause's instructions as predicates, consecutive changes to the same
-- objects for the same duration as one: "gets +2/+2 and gains flying until
-- end of turn".
instructions :: Target.Context -> [Effect.Effect card ability] -> [[Predicate]]
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
  change <- Continuous.modifications Continuous.Created (Target.number who) distributed (Target.keyword context) (ModifyTarget.modification m : more)
  lasting <- Continuous.duration (ModifyTarget.duration m)
  case lasting of
    Nothing -> [MkPredicate (Just who) change [] [] Nothing False]
    -- Free: the duration ends the sentence (Giant Growth) or opens it
    -- (Aspirant's Ascent).
    Just period ->
      [ MkPredicate (Just who) (change <> Text.pack " " <> period) [] [] Nothing False,
        MkPredicate Nothing (period <> Text.pack ", " <> Target.wording who <> Text.pack " " <> change) [] (Target.mentions who) Nothing False
      ]

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
-- sentence (Ancient Tomb), and so does an imperative of "you" beside another
-- player's instruction (Afterlife Insurance). When two share a subject the
-- second drops it ("draws two cards and loses 2 life"). Three or more are not
-- strung together here yet.
joined :: [Text.Text] -> [Predicate] -> [(Text.Text, [SlotName.SlotName])]
joined separators predicates = case predicates of
  [p] -> [(sentences p, allMentions p)]
  [p, q]
    | not (null (after p)) || Maybe.isJust (mana p) || Maybe.isJust (mana q) -> apart
    -- Free for "you": repeated (Ancient Craving) or not (Ambition's Cost).
    | sameSubject p q ->
        [(Prose.sentence (clauseText p <> Text.pack " and " <> clauseText q) <> trailing q, allMentions p <> allMentions q) | fmap Target.wording (subject q) == Just (Text.pack "you")]
          <> [(Prose.sentence (clauseText p <> Text.pack " and " <> verb q) <> trailing q, allMentions p <> mentions q)]
    | implied p || implied q -> apart
    -- Free: "and" (Vampiric Feast) or two sentences (Soul Shred).
    | otherwise -> (Prose.sentence (clauseText p <> Text.pack " and " <> clauseText q) <> trailing q, allMentions p <> allMentions q) : apart
    where
      apart = [(sentences p <> separator <> sentences q, allMentions p <> allMentions q) | separator <- separators]
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
effect :: Target.Context -> Effect.Effect card ability -> [Predicate]
effect context e = case e of
  Effect.DealDamage d -> dealDamage context d
  Effect.Draw d
    | Maybe.isNothing (Draw.slot d) -> do
        count <- Target.cards (Draw.quantity d)
        imperative context (Draw.player d) (Text.pack "draw " <> count) (Text.pack "draws " <> count)
  Effect.GainLife g -> do
    n <- Target.amount (PlayerQuantity.quantity g)
    declarative context (PlayerQuantity.player g) (Text.pack "gain " <> n <> Text.pack " life") (Text.pack "gains " <> n <> Text.pack " life")
  Effect.LoseLife l
    | LifeLoss.cause l == LifeLossCause.ByEffect,
      Maybe.isNothing (LifeLoss.tally l) -> do
        n <- Target.amount (LifeLoss.quantity l)
        declarative context (LifeLoss.player l) (Text.pack "lose " <> n <> Text.pack " life") (Text.pack "loses " <> n <> Text.pack " life")
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
        (symbols, phrase) <- added (ManaAddition.production a) (ManaAddition.count a)
        [MkPredicate Nothing (Text.pack "add " <> phrase) [] [] (Just symbols) False]
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
  | Maybe.isJust (DealDamage.dealer d) || Maybe.isJust (DealDamage.excess d) = []
  | otherwise = do
      let source = Target.MkReference (Target.self context) [] Filter.Singular
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
          rendered <- traverse (damagePart context) groups
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
-- player".
damagePart :: Target.Context -> [DamagePart.DamagePart] -> [(Text.Text, [SlotName.SlotName])]
damagePart context group = case group of
  first : _ -> do
    n <- Target.amount (DamagePart.quantity first)
    refs <- traverse (Target.object context Target.Each . DamagePart.ref) group
    [(n <> Text.pack " damage to " <> Prose.listing "and" (fmap Target.wording refs), concatMap Target.mentions refs)]
  [] -> []

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
