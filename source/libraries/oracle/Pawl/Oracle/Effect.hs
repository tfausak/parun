-- Instructions (Pawl.Types.Effect) as the sentences Oracle text prints them
-- in, and the clauses, modes and modal payloads that hold them (CR 608.2c,
-- CR 700.2).
module Pawl.Oracle.Effect where

import qualified Control.Monad as Monad
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
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
-- slots the verb phrase names, and the mana symbols it adds, which a following
-- addition joins.
data Predicate = MkPredicate
  { subject :: Maybe Target.Reference,
    verb :: Text.Text,
    after :: [Text.Text],
    mentions :: [SlotName.SlotName],
    mana :: Maybe Text.Text
  }
  deriving (Eq, Show)

-- | A modal payload's text. Only a payload of one mode renders yet; a modal
-- spell's "Choose one" is not spelled out here.
modal :: Target.Context -> Modal.Modal card ability -> [Text.Text]
modal context m = case (Foldable.toList (Modal.modes m), Modal.selection m) of
  ([only], ModeSelection.ChooseExactly 1) -> mode context only
  _ -> []

-- | A mode's sentences, each of its target slots named exactly once (CR
-- 601.2c): a slot named twice, or never, means the text is not the mode's.
-- Oracle text runs one sentence on from the last or starts a paragraph, as
-- printings differ (Electrolyze's "Draw a card." stands alone).
mode :: Target.Context -> Mode.Mode card ability -> [Text.Text]
mode context m = do
  let inner = context {Target.slots = Mode.targetSlots m}
  rendered <- traverse (clause inner) (Foldable.toList (Mode.clauses m))
  let named = List.sort (concatMap snd rendered)
  Monad.guard (named == Map.keys (Mode.targetSlots m))
  case fmap fst rendered of
    [] -> [Text.empty]
    first : rest -> Monad.foldM (\text next -> fmap (\separator -> text <> separator <> next) separators) first rest

-- | What separates two sentences: a space, or a new paragraph.
separators :: [Text.Text]
separators = [Text.pack " ", Text.pack "\n"]

-- | A clause's sentences and the slots they name: its instructions, or "you
-- may" and the one instruction you may follow (CR 603.5). A clause gated by a
-- condition, an "if you do" or a payment is not spelled out here, nor a "may"
-- another player decides or one over more than one instruction.
clause :: Target.Context -> Clause.Clause card ability -> [(Text.Text, [SlotName.SlotName])]
clause context c
  | Maybe.isJust (Clause.ifTaken c) || Maybe.isJust (Clause.condition c) || Maybe.isJust (Clause.orElse c) || Maybe.isJust (Clause.payGate c) = []
  | otherwise = do
      predicates <- traverse (effect context) (Foldable.toList (Clause.effects c))
      case (Clause.optionality c, List.foldr addedTogether [] predicates) of
        (Optionality.Mandatory, together) -> joined together
        (Optionality.Optional (PlayerRef.Relative PlayerRelation.You), [p])
          | maybe True ((== Text.pack "you") . Target.wording) (subject p) ->
              [(Prose.sentence (Text.pack "you may " <> verb p) <> trailing p, mentions p)]
        _ -> []

-- | Mana added by consecutive instructions, as Oracle text adds it in one:
-- "Add {C}{C}." (Sol Ring).
addedTogether :: Predicate -> [Predicate] -> [Predicate]
addedTogether p rest = case (mana p, rest) of
  (Just a, q : others)
    | Just b <- mana q -> p {verb = Text.pack "add " <> a <> b, mana = Just (a <> b)} : others
  _ -> p : rest

-- | The instructions of one clause as Oracle text strings them: one sentence
-- with "and", or two sentences or paragraphs, as printings differ (Bargain
-- prints its two on two lines). When two share a subject
-- the second drops it ("draws two cards and loses 2 life"), though older
-- printings repeat a "you". Three or more are not strung together here yet.
joined :: [Predicate] -> [(Text.Text, [SlotName.SlotName])]
joined predicates = case predicates of
  [p] -> [(sentences p, allMentions p)]
  [p, q]
    | not (null (after p)) -> [(sentences p <> separator <> sentences q, allMentions p <> allMentions q) | separator <- separators]
    | sameSubject p q ->
        (Prose.sentence (clauseText p <> Text.pack " and " <> verb q) <> trailing q, allMentions p <> mentions q)
          : [(Prose.sentence (clauseText p <> Text.pack " and " <> clauseText q) <> trailing q, allMentions p <> allMentions q) | fmap Target.wording (subject q) == Just (Text.pack "you")]
    | otherwise ->
        (Prose.sentence (clauseText p <> Text.pack " and " <> clauseText q) <> trailing q, allMentions p <> allMentions q)
          : [(sentences p <> separator <> sentences q, allMentions p <> allMentions q) | separator <- separators]
  _ -> []

-- | Whether two predicates have one subject, so the second can drop it.
sameSubject :: Predicate -> Predicate -> Bool
sameSubject p q = case (subject p, subject q) of
  (Just a, Just b) -> a == b
  _ -> False

-- | The sentences that must follow a predicate, each after a space.
trailing :: Predicate -> Text.Text
trailing p = Text.concat (fmap (Text.pack " " <>) (after p))

-- | The predicate as a sentence, followed by the ones that must follow it.
sentences :: Predicate -> Text.Text
sentences p = Prose.sentence (clauseText p) <> trailing p

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
        [MkPredicate Nothing (Text.pack "destroy " <> Target.wording ref) regenerate (Target.mentions ref) Nothing]
  Effect.Counter c
    | Maybe.isNothing (Counter.slot c),
      Maybe.isNothing (Counter.sources c),
      Maybe.isNothing (Counter.instead c) -> do
        ref <- Target.object context Target.All (Counter.ref c)
        [MkPredicate Nothing (Text.pack "counter " <> Target.wording ref) [] (Target.mentions ref) Nothing]
  Effect.AddMana a
    | ManaAddition.player a == PlayerRef.Relative PlayerRelation.You,
      ManaAddition.retention a == ManaRetention.Ordinary,
      Maybe.isNothing (ManaAddition.restriction a),
      Maybe.isNothing (ManaAddition.rider a),
      Maybe.isNothing (ManaAddition.whenSpent a) -> do
        (symbols, phrase) <- added (ManaAddition.production a) (ManaAddition.count a)
        [MkPredicate Nothing (Text.pack "add " <> phrase) [] [] symbols]
  _ -> []

-- | The mana an instruction adds: "{G}", "{C}{C}", "one mana of any color"
-- (CR 106.1).
added :: ManaProduction.ManaProduction -> Quantity.Quantity -> [(Maybe Text.Text, Text.Text)]
added production count = case (production, count) of
  (ManaProduction.OfType t, Quantity.Literal n)
    | n >= 1 ->
        let symbols = Text.concat (List.genericReplicate n (Text.pack "{" <> Cost.manaType t <> Text.pack "}"))
         in [(Just symbols, symbols)]
  (ManaProduction.AnyColor, Quantity.Literal 1) -> [(Nothing, Text.pack "one mana of any color")]
  _ -> []

-- | "[Source] deals [amount] damage to [recipient]", one part after another
-- ("4 damage to any target and 2 damage to you"), parts sharing an amount
-- sharing it ("X damage to each creature and each player") or not ("1 damage
-- to any target and 1 damage to you", Brothers of Fire), or damage divided
-- among a slot's targets (CR 601.2d).
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
              [MkPredicate (Just source) (Text.pack "deals " <> n <> Text.pack " damage divided as you choose among " <> Target.wording ref) [] (Target.mentions ref) Nothing]
        parts -> do
          groups <- ListUtils.nubOrd [List.groupBy (\a b -> DamagePart.quantity a == DamagePart.quantity b) parts, fmap pure parts]
          rendered <- traverse (damagePart context) groups
          [MkPredicate (Just source) (Text.pack "deals " <> Text.intercalate (Text.pack " and ") (fmap fst rendered)) [] (concatMap snd rendered) Nothing]

-- | Damage parts sharing an amount: "2 damage to each creature and each
-- player".
damagePart :: Target.Context -> [DamagePart.DamagePart] -> [(Text.Text, [SlotName.SlotName])]
damagePart context group = case group of
  first : _ -> do
    n <- Target.amount (DamagePart.quantity first)
    refs <- traverse (Target.object context Target.Each . DamagePart.ref) group
    [(n <> Text.pack " damage to " <> Prose.listing "and" (fmap Target.wording refs), concatMap Target.mentions refs)]
  [] -> []

-- | A player's instruction that current Oracle text gives "you" as an
-- imperative ("Draw two cards.") and older text with its subject ("You draw
-- two cards.").
imperative :: Target.Context -> PlayerRef.PlayerRef -> Text.Text -> Text.Text -> [Predicate]
imperative context ref second third = do
  (who, person) <- Target.player context ref
  case person of
    Target.Second -> [MkPredicate Nothing second [] [] Nothing, MkPredicate (Just who) second [] [] Nothing]
    Target.Third -> [MkPredicate (Just who) third [] [] Nothing]

-- | A player's instruction that always names the player: "You gain 4 life."
declarative :: Target.Context -> PlayerRef.PlayerRef -> Text.Text -> Text.Text -> [Predicate]
declarative context ref second third = do
  (who, person) <- Target.player context ref
  case person of
    Target.Second -> [MkPredicate (Just who) second [] [] Nothing]
    Target.Third -> [MkPredicate (Just who) third [] [] Nothing]
