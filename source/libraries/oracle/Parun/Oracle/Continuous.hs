-- Continuous effects (CR 611) as Oracle text words them: what a modification
-- does to the objects it affects ("gets +3/+3", "gains flying"), for how long,
-- and the static abilities that generate them (CR 604).
module Parun.Oracle.Continuous where

import qualified Control.Monad as Monad
import qualified Data.Bifunctor as Bifunctor
import qualified Data.Containers.ListUtils as ListUtils
import qualified Data.Foldable as Foldable
import qualified Data.List as List
import qualified Data.Maybe as Maybe
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Oracle.Cost as Cost
import qualified Parun.Oracle.Filter as Filter
import qualified Parun.Oracle.Keyword as Keyword.Oracle
import qualified Parun.Oracle.Prose as Prose
import qualified Parun.Oracle.Target as Target
import qualified Parun.Oracle.Trigger as Trigger
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.Arithmetic as Arithmetic
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CharacteristicPT as CharacteristicPT
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostModifier as CostModifier
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.Filter as Filter.Type
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Power as Power
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.RuleAbilities as RuleAbilities
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.Times as Times
import qualified Parun.Types.Toughness as Toughness

-- | The abilities a card's effects grant (CR 113.3), which a change is read
-- into where it grants a rule ("can't be blocked").
type Ability = GrantedAbility.GrantedAbility Card.Card

-- | Who the effect comes from, which picks the verb a keyword takes: an
-- effect a spell or ability creates "gains" it (CR 611.2), a static ability's
-- object "has" it (CR 604.1).
data Origin
  = Created
  | Static
  deriving (Eq, Show)

-- | Modifications to the same objects as one verb phrase agreeing with them,
-- and the words that follow the duration: "gets +2/+2 and gains flying", a
-- run of keywords gained or lost joined ("gain flying and first strike").
-- Several targets "each get" a change to power and toughness (Hearts on
-- Fire), so the change is to each of them. Only power and toughness and
-- keywords are spelled out here.
modifications :: Origin -> Filter.Number -> Bool -> Target.Context -> [Modification.Modification Ability] -> [(Text.Text, Text.Text)]
modifications origin number each context ms = do
  parts <- traverse part (List.groupBy (\a b -> Maybe.isJust (keywordOf a) && fmap fst (keywordOf a) == fmap fst (keywordOf b)) ms)
  case parts of
    [(change, MkTrailing following ends)] -> [(change, following <> ends)]
    _ -> [(Prose.listing "and" [change <> following | (change, MkTrailing following _) <- parts], Text.concat [ends | (_, MkTrailing _ ends) <- parts])]
  where
    verb one many = Text.pack $ case number of
      Filter.Singular -> one
      Filter.Plural -> many
    part group = case group of
      [Modification.ModifyPowerToughness pt] -> do
        (change, trailing) <- powerToughness context (ModifyPowerToughness.power pt) (ModifyPowerToughness.toughness pt)
        [(verb "gets " (if each then "each get " else "get ") <> change, trailing)]
      [Modification.GainAbility a] | Just blockers <- unblockable a -> do
        by <- blockedBy context blockers
        [(Text.pack "can't be blocked" <> by, MkTrailing Text.empty Text.empty)]
      m : _ | Just (gained, _) <- keywordOf m -> do
        keywords <- fmap protectionsJoined (traverse (foldMap (either (Target.keyword context) Keyword.Oracle.family . snd) . keywordOf) group)
        let change = case (gained, origin) of
              (False, _) -> verb "loses " "lose "
              (True, Created) -> verb "gains " "gain "
              (True, Static) -> verb "has " "have "
        [(change <> Prose.listing "and" keywords, MkTrailing Text.empty Text.empty)]
      _ -> []

-- | Protections granted together on one phrase, last, as Oracle text prints
-- them: "and protection from black and from red" (Akroma's Memorial).
protectionsJoined :: [Text.Text] -> [Text.Text]
protectionsJoined ws =
  let prefix = Text.pack "protection "
      (protections, others) = List.partition (Text.isPrefixOf (prefix <> Text.pack "from ")) ws
   in case protections of
        _ : _ : _ -> others <> [prefix <> Prose.listing "and" (fmap (Text.drop (Text.length prefix)) protections)]
        _ -> ws

-- | What follows a change past its duration: what it is "for each", which
-- stands beside the change when another change follows it ("gets +2/+2 for
-- each Aura attached to it and has vigilance"), and the clause defining an X,
-- which ends the sentence. Oracle text puts both after the duration: "gets
-- +1/+1 until end of turn for each land you control" (Naya).
data Trailing = MkTrailing Text.Text Text.Text
  deriving (Eq, Show)

-- | A change to power and toughness, "+3/+3", and the clause defining an X it
-- uses. A change that counts reads "+1/+1 for each card in your hand" or
-- "+X/+X, where X is the number of cards in your hand" (CR 107.3). Free: "for
-- each" (Empyrial Armor) or "where X is" (Inner Calm, Outer Strength).
--
-- Not implemented: a change by a measure, "+X/+0, where X is its power",
-- which the DSL writes as it writes doubling (#5486).
powerToughness :: Target.Context -> Quantity.Quantity -> Quantity.Quantity -> [(Text.Text, Trailing)]
powerToughness context power toughness =
  let plain = do
        p <- signed toughness power
        t <- signed power toughness
        [(p <> Text.pack "/" <> t, MkTrailing Text.empty Text.empty)]
      perEach = do
        (pn, pc) <- Maybe.maybeToList (unit power)
        (tn, tc) <- Maybe.maybeToList (unit toughness)
        counted <- case Maybe.catMaybes [pc, tc] of
          c : cs | all (== c) cs -> [c]
          _ -> []
        a <- Target.amounts context counted
        Target.ForEach 1 e <- [Target.reading a]
        Monad.guard (null (Target.names a))
        p <- signed (Quantity.Literal tn) (Quantity.Literal pn)
        t <- signed (Quantity.Literal pn) (Quantity.Literal tn)
        [(p <> Text.pack "/" <> t, MkTrailing (Text.pack " for each " <> e) Text.empty)]
      variable = do
        v <- case filter (/= Quantity.Literal 0) [power, toughness] of
          v@(Quantity.Count _) : vs | all (== v) vs -> [v]
          _ -> []
        a <- Target.amounts context v
        Target.EqualTo e <- [Target.reading a]
        Monad.guard (null (Target.names a))
        let x q = Text.pack (if q == v then "+X" else "+0")
        [(x power <> Text.pack "/" <> x toughness, MkTrailing Text.empty (Text.pack ", where X is " <> e))]
   in if null plain then perEach <> variable else plain
  where
    -- How much one counted object changes it by, and the count, if any.
    unit q = case q of
      Quantity.Literal n -> Just (n, Nothing)
      Quantity.Count _ -> Just (1, Just q)
      Quantity.Arithmetic (Arithmetic.Times (Times.MkTimes f c@(Quantity.Count _))) -> Just (toInteger f, Just c)
      Quantity.Arithmetic (Arithmetic.Negate inner) -> fmap (Bifunctor.first negate) (unit inner)
      _ -> Nothing

-- | The blockers a granted rule says the object can't be blocked by (CR
-- 509.1b), when that rule is all the ability is.
unblockable :: Ability -> Maybe (Filter.Type.Filter Keyword.Keyword)
unblockable a = case a of
  GrantedAbility.Rules rules
    | [CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy (Affected.Matching Filter.Type.IsSource) blockers Nothing Nothing)] <- RuleAbilities.combatRestrictions rules,
      rules == mempty {RuleAbilities.combatRestrictions = RuleAbilities.combatRestrictions rules} ->
        Just blockers
  _ -> Nothing

-- | The creatures something can't be blocked by, after "can't be blocked":
-- none for any creature, " by Walls", " by creatures with horsemanship", and
-- for all but those of a description " except by Walls".
blockedBy :: Target.Context -> Filter.Type.Filter Keyword.Keyword -> [Text.Text]
blockedBy context f = case f of
  Filter.Type.And [] -> [Text.empty]
  -- "by non-Wall creatures" (Flow of Maggots) is not spelled out here: no
  -- pool card prints it beside "except by Walls" (Invisibility).
  Filter.Type.Not g -> fmap (Text.pack " except by " <>) (creatures g)
  _ -> fmap (Text.pack " by " <>) (creatures f)
  where
    -- A creature type names them alone, "by Walls", the first of
    -- 'Target.creature''s forms.
    creatures g = do
      p <- Filter.phrase g (Target.keyword context) >>= take 1 . Target.creature
      Filter.describe Filter.Plural Target.permanent p

-- | The keyword the modification grants, or with False the one it takes away,
-- or every keyword of a family it takes away (CR 613.1f).
keywordOf :: Modification.Modification ability -> Maybe (Bool, Either Keyword.Keyword KeywordFamily.KeywordFamily)
keywordOf m = case m of
  Modification.GainKeyword k -> Just (True, Left k)
  Modification.LoseKeyword k -> Just (False, Left k)
  Modification.LoseKeywordFamily f -> Just (False, Right f)
  _ -> Nothing

-- | A change to power or toughness with its sign: "+3", "-2", "+X", and a
-- zero signed as the other change is, "+2/+0" and "-2/-0" (Saltfield
-- Recluse). The first argument is the other change.
signed :: Quantity.Quantity -> Quantity.Quantity -> [Text.Text]
signed other q = case q of
  Quantity.Literal n
    | n > 0 -> [Text.pack ("+" <> show n)]
    | n < 0 -> [Text.pack (show n)]
    | Quantity.Literal m <- other, m < 0 -> [Text.pack "-0"]
    | otherwise -> [Text.pack "+0"]
  Quantity.InSlot s | s == Target.xSlot -> [Text.pack "+X"]
  _ -> []

-- | How long a created effect lasts, or nothing for one that lasts until the
-- end of the game, which states no duration (CR 611.2a, Riding the Dilu
-- Horse). Only "until end of turn" is spelled out here.
duration :: Duration.Duration -> [Maybe Text.Text]
duration d = case d of
  Duration.UntilEndOfTurn -> [Just (Text.pack "until end of turn")]
  Duration.Indefinite -> [Nothing]
  _ -> []

-- | A static ability whose effect is one of the above on the objects it
-- affects (CR 604.1): "Creatures you control get +1/+1.", "Enchanted creature
-- gets +2/+2 and has trample.", and one applying only while a condition holds
-- (CR 611.3a): "As long as you control a Forest, this creature gets +1/+2."
-- A zone it functions from, a lingering duration or a name is not spelled out
-- here.
static :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> StaticAbility.StaticAbility Ability -> [Text.Text]
static context attached enchants a
  | Set.null (StaticAbility.functionsFrom a),
    Maybe.isNothing (StaticAbility.lingers a),
    Maybe.isNothing (StaticAbility.name a) =
      let body context' = do
            subject <- affected context' attached enchants (StaticAbility.affected a)
            (verb, defined) <- modifications Static (Target.number subject) False context' (Foldable.toList (StaticAbility.modifications a))
            [Target.wording subject <> Text.pack " " <> verb <> defined]
       in case StaticAbility.condition a of
            Nothing -> fmap Prose.sentence (body context)
            Just c -> do
              words' <- Trigger.condition context c
              word <- Trigger.abilityWord words'
              -- A condition on the source's own status names it first, and
              -- what follows calls it "it": "As long as this creature is
              -- attacking, it gets +2/+0", "This creature gets +2/+0 as long
              -- as it's attacking".
              let itself = Trigger.aboutSource c
                  it = context {Target.self = Text.pack "it"}
              stated <- body (if itself then it else context)
              full <- body context
              after <- if itself then fmap (\w -> maybe w (Text.pack "it's " <>) (Text.stripPrefix (Text.pack "it is ") w)) (Trigger.condition it c) else [words']
              let opened = if Text.isPrefixOf (Target.self context) stated then stated else Prose.decapitalise stated
              -- Free: the condition opens the sentence (Excavating Anurid) or
              -- closes it (Kird Ape), and your turn opens it "During your
              -- turn" (Blood Burglar) or "As long as it's your turn" (Faithful
              -- Pikemaster).
              let openings = [Text.pack "As long as " <> words' <> Text.pack ", "] <> [Text.pack "During your turn, " | words' == Text.pack "it's your turn"]
              [word <> opening <> opened <> Text.pack "." | opening <- openings] <> [word <> Prose.sentence (full <> Text.pack " as long as " <> after)]
  | otherwise = []

-- | A face's static abilities and combat restrictions, an unconditional
-- change to power and toughness and a "can't be blocked" or "can't block" of
-- the objects it affects read as one ability: "Enchanted creature gets +1/+1
-- and can't be blocked except by creatures with flying." (Treetop Bracers),
-- "Enchanted creature gets -1/-1 and can't block." (Crippling Blight). The
-- rest, and the wordings of the one read together. One granting keywords puts
-- them after the restriction (Whispersilk Cloak).
evasive :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> [StaticAbility.StaticAbility Ability] -> [CombatRestriction.CombatRestriction] -> ([StaticAbility.StaticAbility Ability], [CombatRestriction.CombatRestriction], [[Text.Text]])
evasive context attached enchants statics rs =
  case [(s, r, ws) | s <- statics, r <- rs, (a, restrictions) <- restricts r, let ws = together s a restrictions, not (null ws)] of
    (s, r, ws) : _ -> (List.delete s statics, List.delete r rs, [ws])
    [] -> (statics, rs, [])
  where
    restricts r = case r of
      CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy a b Nothing Nothing) -> [(a, fmap (Text.pack "can't be blocked" <>) (blockedBy context b))]
      CombatRestriction.CantBlock (AffectedUnless.MkAffectedUnless a Nothing Nothing Nothing) -> [(a, [Text.pack "can't block"])]
      _ -> []
    together s a restrictions = do
      Monad.guard (s == s {StaticAbility.condition = Nothing, StaticAbility.functionsFrom = Set.empty, StaticAbility.lingers = Nothing, StaticAbility.name = Nothing})
      subject <- affected context attached enchants (StaticAbility.affected s)
      other <- ruled context attached enchants a
      Monad.guard (Target.wording subject == Target.wording other)
      (verb, defined) <- modifications Static (Target.number subject) False context (Foldable.toList (StaticAbility.modifications s))
      Monad.guard (Text.null defined)
      restriction <- restrictions
      let before = Prose.sentence (Target.wording subject <> Text.pack " " <> verb <> Text.pack " and " <> restriction)
          after = Prose.sentence (Target.wording subject <> Text.pack " " <> restriction <> Text.pack " and " <> verb)
      if any (Maybe.isJust . keywordOf) (StaticAbility.modifications s) then [after] else [before]

-- | A characteristic-defining ability (CR 604.3) giving the power or
-- toughness the face prints as a star (CR 208.2): "Nightmare's power and
-- toughness are each equal to the number of Swamps you control." One
-- defining both by different numbers (Tarmogoyf) is not spelled out here.
defining :: Target.Context -> Maybe Power.Power -> Maybe Toughness.Toughness -> CharacteristicPT.CharacteristicPT -> [Text.Text]
defining context power toughness pt = do
  let starred = [(word, q) | (word, Just Quantity.Star, q) <- [("power", fmap Power.unwrap power, CharacteristicPT.power pt), ("toughness", fmap Toughness.unwrap toughness, CharacteristicPT.toughness pt)]]
  (subject, q) <- case starred of
    [(word, q)] -> [(Text.pack (word <> " is"), q)]
    [_, (_, q)] | all ((== q) . snd) starred -> [(Text.pack "power and toughness are each", q)]
    _ -> []
  a <- Target.amounts context q
  Target.EqualTo e <- [Target.reading a]
  Monad.guard (null (Target.names a))
  let plain = Prose.sentence (Target.possessive (Target.self context) <> Text.pack " " <> subject <> Text.pack " equal to " <> e)
  -- Free: a plural instant-or-sorcery count reads "and" (Enigma Drake).
  ListUtils.nubOrd [plain, Text.replace (Text.pack "instant or sorcery cards") (Text.pack "instant and sorcery cards") plain]

-- | Static abilities restricting how permanents attack and block (CR
-- 508.1c, CR 509.1b): "This creature can't block.", "Creatures can't
-- attack.", "This creature can't be blocked by Walls.", one ability each,
-- except that a permanent's "can't attack" and "can't block" are one ability,
-- "can't attack or block" (Pacifism), as are its "can't block" and "can't be
-- blocked" (Tormented Soul). A
-- restriction with an "unless" or a name, or any other restriction, is not
-- spelled out here.
combatRestrictions :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> [CombatRestriction.CombatRestriction] -> [[Text.Text]]
combatRestrictions context attached enchants rs = case rs of
  [] -> []
  CombatRestriction.CantAttack a : CombatRestriction.CantBlock b : rest
    | a == b -> restricted a (Text.pack "can't attack or block") : combatRestrictions context attached enchants rest
  CombatRestriction.CantBlock a@(AffectedUnless.MkAffectedUnless affected' Nothing Nothing Nothing) : CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy affected'' (Filter.Type.And []) Nothing Nothing) : rest
    | affected' == affected'' -> restricted a (Text.pack "can't block and can't be blocked") : combatRestrictions context attached enchants rest
  r : rest -> one r : combatRestrictions context attached enchants rest
  where
    one r = case r of
      CombatRestriction.CantAttack a -> restricted a (Text.pack "can't attack")
      CombatRestriction.CantBlock a -> restricted a (Text.pack "can't block")
      CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy affected' blockers Nothing Nothing) -> do
        subject <- ruled context attached enchants affected'
        by <- blockedBy context blockers
        [Prose.sentence (Target.wording subject <> Text.pack " can't be blocked" <> by)]
      _ -> []
    restricted a verb = case a of
      AffectedUnless.MkAffectedUnless affected' Nothing Nothing Nothing -> do
        subject <- ruled context attached enchants affected'
        [Prose.sentence (Target.wording subject <> Text.pack " " <> verb)]
      _ -> []

-- | A static ability's rule for players (CR 604.1) making spells of a
-- description cost more mana to cast (CR 601.2f): "Red spells cost {2} more
-- to cast.", "Creature spells your opponents cast cost {1} more to cast.",
-- "Black spells you cast cost {B} more to cast." Spells of one kind or
-- another, any other rule, or one with a condition or a name is not spelled
-- out here.
playerRule :: Target.Context -> PlayerStaticAbility.PlayerStaticAbility -> [Text.Text]
playerRule context a = case a of
  PlayerStaticAbility.MkPlayerStaticAbility (PlayerScope.Related relation) Nothing Nothing (PlayerEffect.ModifyCost (CostModifier.MkCostModifier CostSubject.Spells f Nothing Nothing Nothing Nothing (CostChange.Increase k)))
    | not (null (ManaCost.unwrap k)),
      not (any disjoined (conjuncts f)) -> do
        casters <- case relation of
          PlayerRelation.AnyPlayer -> [Text.empty]
          PlayerRelation.Opponent -> [Text.pack " your opponents cast"]
          PlayerRelation.You -> [Text.pack " you cast"]
          _ -> []
        let spell = Filter.noun (Text.pack "spell") (Just (Text.pack "spells"))
        p <- Filter.phrase f (Target.keyword context)
        many <- Filter.describe Filter.Plural Target.permanent (Filter.merge p spell)
        [Prose.sentence (many <> casters <> Text.pack " cost " <> Cost.manaCost k <> Text.pack " more to cast")]
  _ -> []
  where
    conjuncts g = case g of
      Filter.Type.And gs -> gs
      _ -> [g]
    disjoined g = case g of
      Filter.Type.Or _ -> True
      _ -> False

-- | The permanents a rule restricts, as its sentence's subject: as a static
-- ability's, except that permanents described by their noun alone read
-- without "all": "Creatures can't block." (Bedlam).
ruled :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> Affected.Affected -> [Target.Reference]
ruled context attached enchants a = do
  subject <- affected context attached enchants a
  [maybe subject (\rest -> subject {Target.wording = rest}) (Text.stripPrefix (Text.pack "all ") (Target.wording subject))]

-- | The objects a static ability affects, as its sentence's subject. The
-- object its source is attached to is named by the given word: "enchanted"
-- (CR 303.4b, CR 303.4m) or "equipped" (CR 301.5a).
affected :: Target.Context -> Maybe Text.Text -> [TargetSlot.TargetSlot] -> Affected.Affected -> [Target.Reference]
affected context attached enchants a = case a of
  Affected.Attached
    | Just word <- attached,
      [slot] <- enchants -> do
        (one, _) <- Target.described context slot
        [Target.MkReference (word <> Text.pack " " <> one) [] Filter.Singular]
  Affected.Matching Filter.Type.IsSource -> [Target.MkReference (Target.self context) [] Filter.Singular]
  Affected.Matching f
    | elem attachedToSource (conjuncts f) -> do
        word <- Maybe.maybeToList attached
        -- Described by nothing else, the object is a creature when that is
        -- all the source attaches to: an Aura enchanting creatures
        -- (Invisibility), or an Equipment (CR 301.5). Otherwise it is a
        -- permanent (Teferi's Curse).
        one <- case (filter (/= attachedToSource) (conjuncts f), fmap TargetSlot.pool enchants) of
          ([], [Pool.Creatures]) -> [Text.pack "creature"]
          ([], []) -> [Text.pack "creature"]
          (rest, _) -> do
            p <- Filter.phrase (Filter.Type.And rest) (Target.keyword context)
            Filter.describe Filter.Singular Target.permanent p
        [Target.MkReference (word <> Text.pack " " <> one) [] Filter.Singular]
    | otherwise -> Target.object context Target.Affected (ObjectRef.EachMatching f)
  _ -> []
  where
    attachedToSource = Filter.Type.HasAttached Filter.Type.IsSource
    conjuncts g = case g of
      Filter.Type.And gs -> gs
      _ -> [g]

-- | What the object a permanent is attached to is called: "enchanted" for an
-- Aura's, or a creature's with bestow, which is attached as an Aura (CR
-- 702.103b), and "equipped" for an Equipment's.
attachedWord :: Set.Set Subtype.Subtype -> Bool -> Maybe Text.Text
attachedWord subtypes bestowed
  | Set.member Subtype.Aura subtypes || bestowed = Just (Text.pack "enchanted")
  | Set.member Subtype.Equipment subtypes = Just (Text.pack "equipped")
  | otherwise = Nothing

-- | An Aura's enchant ability (CR 702.5a): "Enchant creature". One enchanting
-- a card in a graveyard is not spelled out here.
enchant :: Target.Context -> TargetSlot.TargetSlot -> [Text.Text]
enchant context slot = do
  Monad.guard (case TargetSlot.pool slot of Pool.CardsInGraveyard _ -> False; _ -> True)
  (one, _) <- Target.described context slot
  [Text.pack "Enchant " <> one]

-- | A static ability's replacement effect (CR 614.1): "This land enters
-- tapped." (CR 614.1d). Any other replacement effect, or one with a
-- condition, a zone it functions from or a name, is not spelled out here.
replacement :: Target.Context -> PrintedReplacement.PrintedReplacement card ability effect -> [Text.Text]
replacement context r = case r of
  PrintedReplacement.MkPrintedReplacement Nothing (ReplacementEffect.EntryR (EntryR.MkEntryR Filter.Type.IsSource EntryRewrite.Tapped)) zones Nothing
    | Set.null zones -> [Target.self context <> Text.pack " enters tapped."]
  _ -> []
