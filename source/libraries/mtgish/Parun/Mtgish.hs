-- mtgish's typed card ASTs translated into card data (#5478), so a card the
-- DSL can already express need not be written by hand. A node translated
-- here maps onto exactly one DSL constructor; a node that does not, or that
-- would map only approximately, rejects the whole card, which is never
-- written in part. Parun.Mtgish.accepted then holds every translation to the
-- card's own Oracle text: what Parun.Oracle renders for it must say what the
-- card says.
module Parun.Mtgish where

import qualified Control.Monad as Monad
import qualified Data.Char as Char
import qualified Data.Either as Either
import qualified Data.List as List
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Parun.Extra.Integer as Integer
import qualified Parun.Ingest as Ingest
import qualified Parun.Json.Pair as Pair
import qualified Parun.Json.String as String
import qualified Parun.Json.Value as Value
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Mtgish.Node as Node
import qualified Parun.Oracle as Oracle
import qualified Parun.Oracle.Face as Oracle.Face
import qualified Parun.Oracle.Keyword as Oracle.Keyword
import qualified Parun.Oracle.Target as Oracle.Target
import qualified Parun.Oracle.Trigger as Oracle.Trigger
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Activator as Activator
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.AgainstSlot as AgainstSlot
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.Arithmetic as Arithmetic
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardCount as CardCount
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CharacteristicPT as CharacteristicPT
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.CombatStep as CombatStep
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostChange as CostChange
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostModifier as CostModifier
import qualified Parun.Types.CostSubject as CostSubject
import qualified Parun.Types.Count as Count
import qualified Parun.Types.CountedDiscard as CountedDiscard
import qualified Parun.Types.Counter as Counter
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Create as Create
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.DealDamage as DealDamage
import qualified Parun.Types.DealsDamageToPlayer as DealsDamageToPlayer
import qualified Parun.Types.Destroy as Destroy
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.DestructionRewrite as DestructionRewrite
import qualified Parun.Types.Discard as Discard
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.Draw as Draw
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.DuringPhase as DuringPhase
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.EntryRiders as EntryRiders
import qualified Parun.Types.Equip as Equip
import qualified Parun.Types.EquipTarget as EquipTarget
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ForEach as ForEach
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Layout as Layout
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LifeLoss as LifeLoss
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.LoopMembers as LoopMembers
import qualified Parun.Types.ManaAddition as ManaAddition
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaProduction as ManaProduction
import qualified Parun.Types.ManaRetention as ManaRetention
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.PayBranch as PayBranch
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PayObligation as PayObligation
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerQuantity as PlayerQuantity
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.Power as Power
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Protection as Protection
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RandomCardInHand as RandomCardInHand
import qualified Parun.Types.Regenerability as Regenerability
import qualified Parun.Types.Replace as Replace
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.SacrificeEffect as SacrificeEffect
import qualified Parun.Types.Sacrificer as Sacrificer
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Search as Search
import qualified Parun.Types.SearchDestination as SearchDestination
import qualified Parun.Types.SlotCount as SlotCount
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.StaticAbility as StaticAbility
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TargetCount as TargetCount
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TheseDiscard as TheseDiscard
import qualified Parun.Types.Times as Times
import qualified Parun.Types.Toughness as Toughness
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.TypeLine as TypeLine
import qualified Parun.Types.Uses as Uses
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneScope as ZoneScope

type Translated = Node.Translated

type Face = Face.Face Card.Card

type Ability = GrantedAbility.GrantedAbility Card.Card

type Effect = Effect.Effect Card.Card Ability

type Clause = Clause.Clause Card.Card Ability

type Mode = Mode.Mode Card.Card Ability

type Modal = Modal.Modal Card.Card Ability

type Filter = Filter.Filter Keyword.Keyword

-- | The card a translation is accepted as: one whose Oracle text is known
-- and says what Parun.Oracle renders for it ('Oracle.says'). Otherwise why
-- not, with what it renders as where it renders at all.
accepted :: Card.Card -> Translated Card.Card
accepted translated = case Card.faces translated of
  face NonEmpty.:| []
    | Just text <- Face.oracleText face ->
        if Oracle.says translated (Face.name face) text
          then Right translated
          else Left (Text.pack "renders as: " <> Text.replace (Text.pack "\n") (Text.pack " // ") (Maybe.fromMaybe (Text.pack "(nothing)") (Oracle.render translated)))
  _ -> Left (Text.pack "no Oracle text")

-- | One line of mtgish's AST file as the card it means, or the node kind it
-- stopped at. Only a card of one normal face is read.
card :: Value.Value -> Translated Card.Card
card value = do
  pairs <- Common.asObject value
  let keys = fmap (String.unwrap . Pair.name) pairs
      known = fmap Text.pack ["_OracleCard", "Name", "Typeline", "ManaCost", "Rules", "CardPT", "ColorIndicator"]
  oracleCard <- Common.field "_OracleCard" pairs >>= Common.asText
  Monad.unless (oracleCard == Text.pack "Card") (Left (Text.pack "_OracleCard:" <> oracleCard))
  case filter (\k -> notElem k known) keys of
    [] -> pure ()
    k : _ -> Left (Text.pack "field: " <> k)
  name <- Common.field "Name" pairs >>= Common.asText
  typeLine <- Common.field "Typeline" pairs >>= typeLineOf
  cost <- traverse manaCost (Common.optionalField "ManaCost" pairs)
  indicator <- maybe (Right []) (\v -> Common.asArray v >>= traverse Common.asText >>= traverse (Ingest.enumWord "color")) (Common.optionalField "ColorIndicator" pairs)
  rules <- maybe (Right []) Common.asArray (Common.optionalField "Rules" pairs)
  ruleNodes <- traverse Node.node rules
  let defined t = any ((== t) . Node.tag) ruleNodes
  (power, toughness) <- case Common.optionalField "CardPT" pairs of
    Nothing -> Right (Nothing, Nothing)
    Just pt -> do
      fields <- Common.asObject pt
      p <- Common.field "Power" fields >>= stated (defined "CDA_Power")
      t <- Common.field "Toughness" fields >>= stated (defined "CDA_Toughness")
      Right (Just (Power.MkPower p), Just (Toughness.MkToughness t))
  let face = Oracle.Face.bare (CardName.MkCardName name) Nothing cost (Set.fromList indicator) typeLine power toughness Map.empty
  translated <- Monad.foldM rule face ruleNodes
  pure Card.MkCard {Card.layout = Layout.Normal, Card.faces = translated NonEmpty.:| []}
  where
    stated starred v
      | starred = Right Quantity.Star
      | otherwise = fmap Quantity.Literal (Common.asInteger v)

-- | A type line (CR 205): its words as the enumerated constructors they spell.
typeLineOf :: Value.Value -> Translated TypeLine.TypeLine
typeLineOf value = do
  fields <- Common.asObject value
  let words' key = Common.field key fields >>= Common.asArray >>= traverse Common.asText
  supertypes <- words' "Supertypes" >>= traverse (Ingest.enumWord "supertype")
  types <- words' "Cardtypes" >>= traverse (Ingest.enumWord "type")
  subtypes <- words' "Subtypes" >>= traverse (Ingest.enumWord "subtype")
  pure
    TypeLine.MkTypeLine
      { TypeLine.supertypes = Set.fromList supertypes,
        TypeLine.types = Set.fromList types,
        TypeLine.subtypes = Set.fromList subtypes
      }

-- | A mana cost's symbols (CR 202.1). The pool writes {0} as a cost of no
-- symbols, as Parun.Ingest does.
manaCost :: Value.Value -> Translated ManaCost.ManaCost
manaCost value = do
  spelled <- Common.asArray value >>= traverse (Node.node Monad.>=> spelling)
  Ingest.manaCost (Text.pack (concat spelled))

-- | A mana symbol as MTGJSON spells it, which Parun.Ingest reads: "{2}",
-- "{R/G}" for ManaCostRG, "{G/P}" for ManaCostGP.
spelling :: Node.Node -> Translated String
spelling n = case Node.tag n of
  "ManaCostGeneric" -> do
    k <- Node.argument n >>= Common.asInteger
    Right ("{" <> show k <> "}")
  'M' : 'a' : 'n' : 'a' : 'C' : 'o' : 's' : 't' : letters@(_ : _) | all (\c -> elem c "WUBRGCXSP2") letters -> Right ("{" <> List.intersperse '/' letters <> "}")
  _ -> Node.untranslated n

natural :: Node.Node -> Integer -> Translated Natural.Natural
natural n k = maybe (Node.untranslated n) Right (Integer.toNatural k)

-- Rules ----------------------------------------------------------------------

-- | The face with one more rule (CR 113): a keyword, a spell's instructions,
-- an activated, triggered or static ability, its entering tapped, an enchant
-- ability, a characteristic-defining power or toughness, or a rule its
-- permanents or the players follow.
rule :: Face -> Node.Node -> Translated Face
rule face n = case Node.tag n of
  "SpellActions" -> do
    Monad.unless (Face.spell face == Face.defaultSpell) (Node.untranslated n)
    m <- Node.argument n >>= modal outermost
    pure face {Face.spell = m}
  "Activated" -> do
    (costValue, actionsValue) <- pair n
    c <- costOf costValue
    m <- modal outermost actionsValue
    pure face {Face.activatedAbilities = Face.activatedAbilities face <> [activatedAbility c m]}
  -- "Activate only ..." (CR 602.5).
  "ActivatedWithModifiers" -> do
    as <- Node.arguments n
    case as of
      [costValue, actionsValue, modifierValue] -> do
        c <- costOf costValue
        m <- modal outermost actionsValue
        rs <- Node.node modifierValue >>= activationRestrictions
        pure face {Face.activatedAbilities = Face.activatedAbilities face <> [(activatedAbility c m) {ActivatedAbility.restrictions = rs}]}
      _ -> Node.untranslated n
  "TriggerA" -> do
    (eventValue, actionsValue) <- pair n
    (condition, context) <- Node.node eventValue >>= trigger
    m <- modal context actionsValue
    pure face {Face.triggeredAbilities = Face.triggeredAbilities face <> [triggeredAbility condition m]}
  "TriggerI" -> do
    (eventValue, conditionValue, actionsValue) <- triple n
    (condition', context) <- Node.node eventValue >>= trigger
    gate <- Node.node conditionValue >>= intervening context
    m <- modal context actionsValue
    pure face {Face.triggeredAbilities = Face.triggeredAbilities face <> [(triggeredAbility condition' m) {TriggeredAbility.intervening = Just gate}]}
  "CDA_Types" -> do
    types <- Node.child n
    if Node.tag types == "Changeling" && Maybe.isNothing (Node.args types) then keyword Keyword.Changeling else Node.untranslated types
  "EnchantPermanent" -> do
    enchanted <- Node.argument n >>= permanentSlot outermost
    pure face {Face.enchant = Face.enchant face <> [enchanted]}
  "PermanentLayerEffect" -> do
    (who, changes) <- pair n
    affected <- Node.node who >>= affectedOf face
    modifications <- Common.asArray changes >>= traverse (Node.node Monad.>=> staticModification)
    static face affected (concat modifications)
  "EachPermanentLayerEffect" -> do
    (who, changes) <- pair n
    f <- permanents outermost who
    modifications <- Common.asArray changes >>= traverse (Node.node Monad.>=> staticModification)
    static face (Affected.Matching f) (concat modifications)
  "PermanentRuleEffect" -> do
    (who, rules) <- pair n
    affected <- Node.node who >>= affectedOf face
    Common.asArray rules >>= Monad.foldM (\f r -> Node.node r >>= permanentRule f affected) face
  "EachPermanentRuleEffect" -> do
    (who, rules) <- pair n
    f <- permanents outermost who
    Common.asArray rules >>= Monad.foldM (\g r -> Node.node r >>= permanentRule g (Affected.Matching f)) face
  "EachPlayerEffect" -> do
    (who, effects') <- pair n
    relation <- players who
    rows <- Common.asArray effects' >>= traverse (Node.node Monad.>=> playerRule)
    pure face {Face.playerAbilities = Face.playerAbilities face <> [PlayerStaticAbility.MkPlayerStaticAbility (PlayerScope.Related relation) Nothing Nothing e | e <- rows]}
  -- "This land enters tapped" (CR 614.1d).
  "AsPermanentEnters" -> do
    (who, replacements) <- pair n
    p <- Node.node who
    Monad.unless (Node.tag p == "ThisPermanent") (Node.untranslated p)
    rewrites <- Common.asArray replacements >>= traverse Node.node
    case rewrites of
      [r] | Node.tag r == "EntersTapped", Maybe.isNothing (Node.args r) -> pure face {Face.replacementEffects = Face.replacementEffects face <> [entersTapped]}
      r : _ -> Node.untranslated r
      [] -> Node.untranslated n
  "CDA_Power" -> defining n (\q pt -> pt {CharacteristicPT.power = q})
  "CDA_Toughness" -> defining n (\q pt -> pt {CharacteristicPT.toughness = q})
  "Equip" -> do
    (quality, price) <- pair n
    f <- permanents outermost quality
    Monad.unless (f == Filter.HasCardType CardType.Creature) (Node.untranslated n)
    c <- costOf price
    keyword (Keyword.Equip Equip.MkEquip {Equip.cost = c, Equip.quality = Nothing, Equip.target = EquipTarget.Creature})
  _ -> keywordRule n >>= keyword
  where
    static f affected modifications = case modifications of
      m : ms -> pure f {Face.staticAbilities = Face.staticAbilities f <> [staticAbility affected (m NonEmpty.:| ms)]}
      [] -> Node.untranslated n
    -- One ability defining one box is written into both, as
    -- Parun.Codec.Face writes it; the printed number in the other box wins
    -- (Parun.Engine.Projection.View.seedCharacteristicPT).
    defining node' set = do
      q <- Node.argument node' >>= quantity outermost
      let pt = Maybe.fromMaybe (CharacteristicPT.MkCharacteristicPT q q) (Face.characteristicPT face)
      pure face {Face.characteristicPT = Just (set q pt)}
    keyword k = pure face {Face.keywords = Map.insertWith (+) k 1 (Face.keywords face)}

-- | Two arguments.
pair :: Node.Node -> Translated (Value.Value, Value.Value)
pair n = do
  as <- Node.arguments n
  case as of
    [a, b] -> Right (a, b)
    _ -> Node.untranslated n

-- | Three arguments.
triple :: Node.Node -> Translated (Value.Value, Value.Value, Value.Value)
triple n = do
  as <- Node.arguments n
  case as of
    [a, b, c] -> Right (a, b, c)
    _ -> Node.untranslated n

activatedAbility :: Cost.Cost Keyword.Keyword -> Modal -> ActivatedAbility.ActivatedAbility Card.Card Ability
activatedAbility c m =
  ActivatedAbility.MkActivatedAbility
    { ActivatedAbility.cost = c,
      ActivatedAbility.maximumX = [],
      ActivatedAbility.minimumX = 0,
      ActivatedAbility.definedX = Nothing,
      ActivatedAbility.modal = m,
      ActivatedAbility.restrictions = [],
      ActivatedAbility.activator = Activator.Controller,
      ActivatedAbility.condition = Nothing,
      ActivatedAbility.name = Nothing,
      ActivatedAbility.keyword = Nothing
    }

triggeredAbility :: TriggerCondition.TriggerCondition -> Modal -> TriggeredAbility.TriggeredAbility Card.Card Ability
triggeredAbility condition m =
  TriggeredAbility.MkTriggeredAbility
    { TriggeredAbility.condition = condition,
      TriggeredAbility.modal = m,
      TriggeredAbility.intervening = Nothing,
      TriggeredAbility.name = Nothing,
      TriggeredAbility.limit = TriggerLimit.Unlimited,
      TriggeredAbility.functionsFrom = Set.empty
    }

-- | The clauses of an activated ability's "Activate only ..." rider (CR
-- 602.5): its timing (CR 307.5, CR 602.5e), how often (CR 602.5b), or your
-- turn or upkeep (CR 102.1, CR 503).
activationRestrictions :: Node.Node -> Translated [ActivationRestriction.ActivationRestriction]
activationRestrictions n = case Node.tag n of
  "And" -> fmap concat (Node.arguments n >>= traverse (Node.node Monad.>=> activationRestrictions))
  "ActivateOnlyAsASorcery" -> Right [ActivationRestriction.SorcerySpeed]
  "ActivateOnlyAsAnInstant" -> Right [ActivationRestriction.InstantSpeed]
  "ActivateOnlyOnceEachTurn" -> Right [ActivationRestriction.OnlyOnceEachTurn]
  "ActivateOnlyOnce" -> Right [ActivationRestriction.OnlyOnce]
  "ActivateOnlyIf" -> do
    c <- Node.child n
    (who, test) <- if Node.tag c == "PlayerPassesFilter" then pair c else Node.untranslated c
    p <- Node.node who
    Monad.unless (Node.tag p == "You") (Node.untranslated p)
    t <- Node.node test
    case Node.tag t of
      "IsTheirTurn" -> Right [ActivationRestriction.DuringTurn TurnScope.ControllersTurn]
      "IsTheirUpkeep" -> Right [ActivationRestriction.DuringPhase (DuringPhase.MkDuringPhase (PhaseSelector.Step (Phase.Beginning BeginningStep.Upkeep)) TurnScope.ControllersTurn)]
      _ -> Node.untranslated t
  _ -> Node.untranslated n

staticAbility :: Affected.Affected -> NonEmpty.NonEmpty (Modification.Modification Ability) -> StaticAbility.StaticAbility Ability
staticAbility affected modifications =
  StaticAbility.MkStaticAbility
    { StaticAbility.affected = affected,
      StaticAbility.condition = Nothing,
      StaticAbility.functionsFrom = Set.empty,
      StaticAbility.lingers = Nothing,
      StaticAbility.name = Nothing,
      StaticAbility.modifications = modifications
    }

-- | The source's entering tapped (CR 614.1d).
entersTapped :: PrintedReplacement.PrintedReplacement Card.Card Ability Effect
entersTapped =
  PrintedReplacement.MkPrintedReplacement
    { PrintedReplacement.condition = Nothing,
      PrintedReplacement.effect = ReplacementEffect.EntryR EntryR.MkEntryR {EntryR.matching = Filter.IsSource, EntryR.rewrite = EntryRewrite.Tapped},
      PrintedReplacement.functionsFrom = Set.empty,
      PrintedReplacement.name = Nothing
    }

-- | The face with one more rule its permanents follow: that they can't
-- attack (CR 508.1c) or block (CR 509.1b).
permanentRule :: Face -> Affected.Affected -> Node.Node -> Translated Face
permanentRule face affected n
  | Maybe.isJust (Node.args n) = Node.untranslated n
  | otherwise = case Node.tag n of
      "CantAttack" -> combat (CombatRestriction.CantAttack unless)
      "CantBlock" -> combat (CombatRestriction.CantBlock unless)
      _ -> Node.untranslated n
  where
    unless = AffectedUnless.MkAffectedUnless {AffectedUnless.affected = affected, AffectedUnless.unless = Nothing, AffectedUnless.name = Nothing, AffectedUnless.amount = Nothing}
    combat r = Right face {Face.combatRestrictions = Face.combatRestrictions face <> [r]}

-- | A rule players follow: spells of a description cost more mana to cast
-- (CR 601.2f).
playerRule :: Node.Node -> Translated PlayerEffect.PlayerEffect
playerRule n = case Node.tag n of
  "IncreaseSpellCost" -> do
    (what, price) <- pair n
    f <- spells what
    c <- costOf price
    k <- case (Cost.mana c, Cost.components c) of
      (Just m, []) | not (null (ManaCost.unwrap m)), all plain (ManaCost.unwrap m) -> Right m
      _ -> Node.untranslated n
    Right (PlayerEffect.ModifyCost CostModifier.MkCostModifier {CostModifier.subject = CostSubject.Spells, CostModifier.matching = Maybe.fromMaybe (Filter.And []) f, CostModifier.whichTargets = Nothing, CostModifier.perTarget = Nothing, CostModifier.perEach = Nothing, CostModifier.onlyFirst = Nothing, CostModifier.change = CostChange.Increase k})
  _ -> Node.untranslated n
  where
    -- Generic and typed symbols: a hybrid, Phyrexian or {X} symbol in an
    -- increase would reach CR 601.2f unannounced (CR 601.2b).
    plain s = case s of
      ManaSymbol.Generic _ -> True
      ManaSymbol.OfType _ -> True
      _ -> False

-- | The objects a static ability of a permanent affects: the one it is
-- attached to (CR 303.4m), or itself.
affectedOf :: Face -> Node.Node -> Translated Affected.Affected
affectedOf face n = case Node.tag n of
  -- What the source is attached to (CR 303.4b, CR 301.5a), as the pool
  -- describes it: a permanent of the type the enchant ability names, or
  -- for an Equipment a creature.
  "HostPermanent" -> do
    let subtypes = TypeLine.subtypes (Face.typeLine face)
    host <- case Face.enchant face of
      [enchanted]
        | Set.member Subtype.Aura subtypes -> case (TargetSlot.pool enchanted, TargetSlot.filter enchanted) of
            (Pool.Creatures, _) -> Right (Filter.HasCardType CardType.Creature)
            (Pool.Permanents, Just f@(Filter.HasCardType _)) -> Right f
            _ -> Node.untranslated n
      [] | Set.member Subtype.Equipment subtypes -> Right (Filter.HasCardType CardType.Creature)
      _ -> Node.untranslated n
    Right (Affected.Matching (Filter.And [host, Filter.HasAttached Filter.IsSource]))
  "ThisPermanent" -> Right (Affected.Matching Filter.IsSource)
  _ -> Node.untranslated n

-- | A static ability's change to the objects it affects (CR 611.3a).
staticModification :: Node.Node -> Translated [Modification.Modification Ability]
staticModification n = case Node.tag n of
  "AdjustPT" -> fmap pure (adjusted n)
  "AddAbility" -> granted n
  _ -> Node.untranslated n

-- | A change to power and toughness, "+1/+2" (CR 613.4c).
adjusted :: Node.Node -> Translated (Modification.Modification Ability)
adjusted n = do
  (p, t) <- pair n
  power <- number n p
  toughness <- number n t
  pure (Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Literal power) (Quantity.Literal toughness)))

-- | Keywords granted (CR 613.1f), each a modification of its own.
granted :: Node.Node -> Translated [Modification.Modification Ability]
granted n = do
  rules <- Node.arguments n >>= traverse Node.node
  traverse (fmap Modification.GainKeyword . keywordRule) rules

-- Keywords --------------------------------------------------------------------

-- | A keyword ability (CR 702) as the rule naming it: one that stands alone
-- (Flying), a landwalk naming a basic land type, or protection from colours.
keywordRule :: Node.Node -> Translated Keyword.Keyword
keywordRule n = case Node.tag n of
  "Landwalk" -> do
    land <- Node.child n
    case Node.tag land of
      "IsLandType" -> do
        name <- Node.argument land >>= Common.asText
        s <- Ingest.enumWord "subtype" name
        let k = Keyword.Landwalk (Filter.HasSubtype s)
        if elem k Oracle.Keyword.landwalks then Right k else Node.untranslated land
      _ -> Node.untranslated land
  "Protection" -> do
    from <- Node.child n
    case Node.tag from of
      "FromColor" -> do
        colours <- Node.child from
        case Node.tag colours of
          "Colors" -> do
            cs <- Node.arguments colours >>= traverse (Node.node Monad.>=> colour)
            case cs of
              [c] -> Right (Keyword.Protection (Protection.MkProtection (Filter.HasColor c) Nothing))
              _ -> Node.untranslated colours
          _ -> Node.untranslated colours
      _ -> Node.untranslated from
  t
    | Maybe.isNothing (Node.args n), Just k <- Map.lookup (Text.toLower (Text.pack t)) standalones -> Right k
    | Just k <- lookup t numbered -> do
        v <- Node.argument n
        m <- either (const (Node.node v >>= integer)) Right (number n v)
        fmap k (natural n m)
    | Just k <- lookup t costed -> fmap k (Node.argument n >>= costOf)
  _ -> Node.untranslated n

-- | The keywords that carry a number (CR 702), by mtgish's name for each.
numbered :: [(String, Natural.Natural -> Keyword.Keyword)]
numbered =
  [ ("Rampage", Keyword.Rampage),
    ("Fading", Keyword.Fading),
    ("Amplify", Keyword.Amplify),
    ("Bushido", Keyword.Bushido),
    ("Soulshift", Keyword.Soulshift),
    ("Dredge", Keyword.Dredge),
    ("Graft", Keyword.Graft),
    ("Absorb", Keyword.Absorb),
    ("Frenzy", Keyword.Frenzy),
    ("Poisonous", Keyword.Poisonous),
    ("Annihilator", Keyword.Annihilator),
    ("Tribute", Keyword.Tribute),
    ("Renown", Keyword.Renown),
    ("Fabricate", Keyword.Fabricate),
    ("Afflict", Keyword.Afflict),
    ("Toxic", Keyword.Toxic)
  ]

-- | The keywords that carry a cost (CR 702), by mtgish's name for each.
costed :: [(String, Cost.Cost Keyword.Keyword -> Keyword.Keyword)]
costed =
  [ ("Echo", Keyword.Echo),
    ("CumulativeUpkeep", Keyword.CumulativeUpkeep),
    ("Buyback", Keyword.Buyback),
    ("Kicker", Keyword.Kicker),
    ("Flashback", Keyword.Flashback),
    ("Evoke", Keyword.Evoke),
    ("Unearth", Keyword.Unearth),
    ("Outlast", Keyword.Outlast),
    ("Dash", Keyword.Dash)
  ]

-- | The keywords that stand alone, by their printed name run together.
standalones :: Map.Map Text.Text Keyword.Keyword
standalones = Map.fromList [(Text.toLower (Text.filter Char.isAlpha p), k) | k <- Oracle.Keyword.standalone, p : _ <- [Oracle.Keyword.printed Text.empty k]]

colour :: Node.Node -> Translated Color.Color
colour n = case Node.family n of
  "Color" -> Ingest.enumWord "color" (Text.pack (Node.tag n))
  _ -> Node.untranslated n

-- Costs -----------------------------------------------------------------------

-- | An activated ability's cost (CR 602.1a): mana, and components in order.
costOf :: Value.Value -> Translated (Cost.Cost Keyword.Keyword)
costOf value = do
  n <- Node.node value
  parts <- case Node.tag n of
    "And" -> Node.arguments n >>= traverse (Node.node Monad.>=> costPart)
    _ -> fmap pure (costPart n)
  let manas = Either.lefts parts
      components = Either.rights parts
  mana <- case manas of
    [] -> Right (ManaCost.MkManaCost [])
    [m] -> Right m
    _ -> Node.untranslated n
  pure Cost.MkCost {Cost.mana = Just mana, Cost.components = components}

costPart :: Node.Node -> Translated (Either ManaCost.ManaCost (CostComponent.CostComponent Keyword.Keyword))
costPart n = case Node.tag n of
  "PayMana" -> fmap Left (Node.argument n >>= manaCost)
  "TapPermanent" -> itself CostComponent.TapThis
  "UntapPermanent" -> itself CostComponent.UntapThis
  "SacrificePermanent" -> itself CostComponent.SacrificeThis
  "SacrificeAPermanent" -> do
    f <- Node.argument n >>= permanents outermost
    Right (Right (CostComponent.Sacrifice Sacrifice.MkSacrifice {Sacrifice.count = CostAmount.Fixed 1, Sacrifice.whichPermanents = f}))
  "PayLife" -> do
    k <- Node.child n >>= integer
    m <- natural n k
    Right (Right (CostComponent.PayLife (CostAmount.Fixed m)))
  "DiscardHand" -> Right (Right (CostComponent.DiscardCards DiscardCards.MkDiscardCards {DiscardCards.count = CardCount.Every, DiscardCards.whichCards = Filter.And []}))
  _ -> Node.untranslated n
  where
    itself c = do
      p <- Node.child n
      if Node.tag p == "ThisPermanent" then Right (Right c) else Node.untranslated p

-- | A number the node carries bare, or the node's own rejection for
-- anything else ("AdjustPTX"'s X).
number :: Node.Node -> Value.Value -> Translated Integer
number n v = either (const (Node.untranslated n)) Right (Common.asInteger v)

-- | A number printed as one.
integer :: Node.Node -> Translated Integer
integer n = case Node.tag n of
  "Integer" -> Node.argument n >>= Common.asInteger
  _ -> Node.untranslated n

-- Triggers --------------------------------------------------------------------

-- | A trigger event (CR 603.1) and what the ability's instructions call the
-- objects and players it names.
trigger :: Node.Node -> Translated (TriggerCondition.TriggerCondition, Context)
trigger n = case Node.tag n of
  "WhenAPermanentEntersTheBattlefield" -> do
    who <- Node.argument n
    case single who of
      Just "ThisPermanent" -> Right (TriggerCondition.SelfEnters, bound [("ThatEnteringPermanent", Oracle.Target.selfSlot)])
      Just _ -> Node.untranslated n
      Nothing -> do
        f <- permanents outermost who
        Right (TriggerCondition.PermanentEnters f, bound [("ThatEnteringPermanent", Oracle.Target.becameSlot)])
  "WhenAPermanentDies" -> do
    who <- Node.argument n
    case single who of
      Just "ThisPermanent" -> Right (TriggerCondition.SelfDies, bound [])
      Just _ -> Node.untranslated n
      Nothing -> do
        f <- permanents outermost who
        Right (TriggerCondition.PermanentDies f, bound [("Trigger_ThatPermanent", Oracle.Target.becameSlot), ("Trigger_ThatCreature", Oracle.Target.becameSlot)])
  "WhenACreatureAttacks" -> itself (TriggerCondition.SelfAttacks TriggerFrequency.EveryTime)
  "WhenACreatureAttacksAndIsntBlocked" -> itself TriggerCondition.SelfAttacksUnblocked
  "WhenACreatureBlocks" -> itself TriggerCondition.SelfBlocks
  "WhenACreatureBecomesBlocked" -> itself TriggerCondition.SelfBecomesBlocked
  "WhenACreatureBlocksACreature" -> other TriggerCondition.SelfBlocksCreature Oracle.Trigger.thatAttacker
  "WhenACreatureBecomesBlockedByACreature" -> other TriggerCondition.SelfBecomesBlockedBy Oracle.Trigger.thatBlocker
  "WhenACreatureDealsCombatDamageToAPlayer" -> damaged TriggerCondition.SelfDealsCombatDamageToPlayer
  "WhenAPermanentDealsDamageToAPlayer" -> damaged (TriggerCondition.DealsDamageToPlayer . DealsDamageToPlayer.MkDealsDamageToPlayer ActingPermanent.Self)
  "AtTheBeginningOfAPlayersUpkeep" -> step (Phase.Beginning BeginningStep.Upkeep)
  "AtTheBeginningOfAPlayersDrawStep" -> step (Phase.Beginning BeginningStep.DrawStep)
  "AtTheBeginningOfAPlayersEndStep" -> step (Phase.Ending EndingStep.EndStep)
  "AtTheBeginningOfCombatDuringAPlayersTurn" -> step (Phase.Combat CombatStep.BeginningOfCombat)
  -- CR 601.2i: the caster is the spell's controller (CR 112.2), which the
  -- spell's filter names.
  "WhenAPlayerCastsASpell" -> do
    (who, what) <- pair n
    relation <- players who
    f <- spells what
    let caster = [Filter.ControlledBy relation | relation /= PlayerRelation.AnyPlayer]
        spellCast = SpellCast.MkSpellCast {SpellCast.filter = conjoined (foldMap conjuncts f <> caster), SpellCast.scope = TurnScope.EachTurn, SpellCast.zone = Nothing, SpellCast.ordinal = Nothing, SpellCast.phase = Nothing, SpellCast.copies = False}
    Right (TriggerCondition.SpellCast spellCast, bound [("Trigger_ThatPlayer", Oracle.Trigger.thatPlayer), ("Trigger_ThatSpell", Oracle.Trigger.castSpell)])
  "AtTheBeginningOfTheEndStep" -> Right (TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Ending EndingStep.EndStep) Nothing TurnScope.EachTurn), outermost)
  _ -> Node.untranslated n
  where
    bound pairs = outermost {bindings = Map.fromList pairs}
    -- The source's own event, which calls the source "that creature" too.
    itself condition = do
      who <- Node.argument n
      case single who of
        Just "ThisPermanent" -> Right (condition, bound [("Trigger_ThatCreature", Oracle.Target.selfSlot), ("Trigger_DefendingPlayer", Oracle.Trigger.thatPlayer)])
        _ -> Node.untranslated n
    -- The source's event with another creature, of a description.
    other condition slot' = do
      (who, what) <- pair n
      Monad.unless (single who == Just "ThisPermanent") (Node.untranslated n)
      f <- permanents outermost what
      Right (condition f, bound [("Trigger_ThatCreature", Oracle.Target.selfSlot), ("Trigger_ThatOtherPermanent", slot'), ("Trigger_ThatOtherCreature", slot')])
    -- The source dealing damage to a player of a relation.
    damaged condition = do
      (who, whom) <- pair n
      Monad.unless (single who == Just "ThisPermanent") (Node.untranslated n)
      relation <- players whom
      Right (condition relation, bound [("Trigger_ThatCreature", Oracle.Target.selfSlot), ("Trigger_ThatPlayer", Oracle.Trigger.thatPlayer)])
    step phase = do
      whose <- Node.argument n >>= players
      scope <- case whose of
        PlayerRelation.You -> Right TurnScope.ControllersTurn
        PlayerRelation.AnyPlayer -> Right TurnScope.EachTurn
        PlayerRelation.Opponent -> Right TurnScope.OpponentsTurn
        _ -> Node.untranslated n
      Right (TriggerCondition.StepBegins (StepBegins.MkStepBegins phase Nothing scope), bound [("Trigger_ThatPlayer", Oracle.Trigger.thatPlayer)])

-- | An intervening "if" clause (CR 603.4): a count of cards in your hand,
-- of permanents you control, or of permanents on the battlefield.
intervening :: Context -> Node.Node -> Translated Condition.Condition
intervening context n = case Node.tag n of
  "NoPermanentsPassFilter" -> do
    (what, place) <- pair n
    onBattlefield place
    f <- permanents context what
    Right (compares (battlefield f) Comparison.Exactly 0)
  "PlayerPassesFilter" -> do
    (who, test) <- pair n
    p <- Node.node who
    Monad.unless (Node.tag p == "You") (Node.untranslated p)
    t <- Node.node test
    case Node.tag t of
      "NumCardsInHandIs" -> do
        c <- Node.child t
        comparison <- comparisonOf c
        k <- Node.child c >>= integer
        Right (compares (Count.MkCount (Scope.InZone (InZone.MkInZone Zone.Hand (PlayerRef.Relative PlayerRelation.You))) (Filter.And []) Aggregation.Members) comparison k)
      "ControlsA" -> do
        f <- Node.argument t >>= permanents context
        Right (compares (battlefield (conjoined (conjuncts f <> [Filter.ControlledBy PlayerRelation.You]))) Comparison.AtLeast 1)
      _ -> Node.untranslated t
  _ -> Node.untranslated n
  where
    battlefield f = Count.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) f Aggregation.Members
    compares c comparison k = Condition.Compares (Compares.MkCompares (Quantity.Count c) comparison (Quantity.Literal k))
    onBattlefield v = do
      place <- Node.node v
      Monad.unless (Node.tag place == "OnTheBattlefield") (Node.untranslated place)

-- | A comparison (CR 107.1) as mtgish names it.
comparisonOf :: Node.Node -> Translated Comparison.Comparison
comparisonOf n = case Node.tag n of
  "EqualTo" -> Right Comparison.Exactly
  "GreaterThanOrEqualTo" -> Right Comparison.AtLeast
  "LessThanOrEqualTo" -> Right Comparison.AtMost
  "GreaterThan" -> Right Comparison.GreaterThan
  "LessThan" -> Right Comparison.LessThan
  _ -> Node.untranslated n

-- | A filter's conjuncts.
conjuncts :: Filter -> [Filter]
conjuncts f = case f of
  Filter.And fs -> fs
  _ -> [f]

-- | Conjuncts as one filter: none is every object, one is itself.
conjoined :: [Filter] -> Filter
conjoined fs = case fs of
  [f] -> f
  _ -> Filter.And fs

-- | The one permanent a "SinglePermanent" group names, by its node's tag.
single :: Value.Value -> Maybe String
single value = case Node.node value of
  Right n | Node.tag n == "SinglePermanent", Right p <- Node.child n -> Just (Node.tag p)
  _ -> Nothing

-- Instructions ----------------------------------------------------------------

-- | What the nodes an ability's instructions use to name things stand for:
-- the target slots in scope, by the reference mtgish names each with
-- ("Ref_TargetPermanent"), and the objects and players its trigger event
-- names ("Trigger_ThatPlayer").
data Context = MkContext
  { references :: Map.Map String SlotName.SlotName,
    bindings :: Map.Map String SlotName.SlotName,
    -- | The player "each player" instructions are addressed to, one at a
    -- time, which mtgish calls "ActionPlayer".
    actor :: Maybe PlayerRef.PlayerRef,
    -- | The slot an amount is divided among (CR 601.2d).
    dividing :: Maybe SlotName.SlotName,
    -- | Which kind of mana of an "or" the mode adds: "Add {W} or {U}" is
    -- one mode per kind.
    manaChoice :: Maybe Int
  }
  deriving (Eq, Show)

-- | An ability's context before its trigger event or targets name anything.
outermost :: Context
outermost = MkContext Map.empty Map.empty Nothing Nothing Nothing

-- | Instructions as a modal payload: one mode, each of a "Choose one"'s, or
-- one for each kind of mana an "or" of mana chooses among.
modal :: Context -> Value.Value -> Translated Modal
modal context value = do
  n <- Node.node value
  modes <- case (Node.tag n, manaOptions value) of
    ("Modal_ChooseOne", _) -> Node.arguments n >>= traverse (mode context)
    (_, []) -> fmap pure (mode context value)
    (_, [k]) | k > 1 -> traverse (\i -> mode context {manaChoice = Just i} value) [0 .. k - 1]
    _ -> Node.untranslated n
  pure Modal.MkModal {Modal.modes = Seq.fromList modes, Modal.selection = ModeSelection.ChooseExactly 1}

-- | How many kinds of mana each "or" of mana in the value chooses among.
manaOptions :: Value.Value -> [Int]
manaOptions value = case (Common.asObject value, Common.asArray value) of
  (Right pairs, _)
    | Right n <- Node.node value,
      Node.family n == "ManaProduce",
      Node.tag n == "Or" ->
        [either (const 0) length (Node.arguments n)]
    | otherwise -> concatMap (manaOptions . Pair.value) pairs
  (_, Right values) -> concatMap manaOptions values
  _ -> []

-- | One mode: its instructions, after the targets they choose (CR 601.2c).
mode :: Context -> Value.Value -> Translated Mode
mode context value = do
  n <- Node.node value
  case Node.tag n of
    "ActionList" -> do
      actions <- Node.arguments n
      cs <- clauses context actions
      pure Mode.MkMode {Mode.clauses = Seq.fromList cs, Mode.targetSlots = Map.empty}
    "Targeted" -> do
      (targetsValue, inner) <- pair n
      targetNodes <- Common.asArray targetsValue >>= traverse Node.node
      refs <- traverse reference targetNodes
      let named = slotNames refs
          inScope = context {references = Map.union (Map.fromList named) (references context)}
      slots <- traverse (target inScope) targetNodes
      m <- mode inScope inner
      Monad.unless (Map.null (Mode.targetSlots m)) (Node.untranslated n)
      pure m {Mode.targetSlots = Map.fromList (zip (fmap snd named) slots)}
    "TargetedDistributed" -> do
      as <- Node.arguments n
      case as of
        [targetsValue, distribution, inner] -> do
          targetNodes <- Common.asArray targetsValue >>= traverse Node.node
          d <- Node.node distribution
          total <- case Node.tag d of
            "DistributeNumberAmongTargets" -> Node.argument d >>= quantity context
            _ -> Node.untranslated d
          (ref, divided) <- case targetNodes of
            [t] -> distributed context total t
            _ -> Node.untranslated n
          let name = SlotName.MkSlotName (Text.pack "target")
          m <- mode context {references = Map.insert ref name (references context), dividing = Just name} inner
          Monad.unless (Map.null (Mode.targetSlots m)) (Node.untranslated n)
          pure m {Mode.targetSlots = Map.singleton name divided {TargetSlot.divided = Just total}}
        _ -> Node.untranslated n
    _ -> Node.untranslated n

-- | A target among which an amount is divided (CR 601.2d), and the
-- reference naming it: "one or two targets" (between one and a number), or
-- "any number of targets" for up to the amount divided, which caps how many
-- anyway, as each is given at least one.
distributed :: Context -> Quantity.Quantity -> Node.Node -> Translated (String, TargetSlot.TargetSlot)
distributed context total n = case Node.tag n of
  "UptoNumberAnyTargets" -> Node.argument n >>= upTo . (,) (slot Pool.AnyTarget Nothing)
  "BetweenOneAndNumberAnyTargets" -> Node.argument n >>= between . (,) (slot Pool.AnyTarget Nothing)
  "UptoNumberTargetPermanents" -> permanents' upTo
  "BetweenOneAndNumberTargetPermanents" -> permanents' between
  _ -> Node.untranslated n
  where
    reference' = if Node.tag n == "UptoNumberAnyTargets" || Node.tag n == "BetweenOneAndNumberAnyTargets" then "Ref_AnyTargets" else "Ref_TargetPermanents"
    upTo (s, amount) = do
      most <- quantity context amount
      Monad.unless (most == total) (Node.untranslated n)
      Right (reference', s {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 0 Nothing)})
    between (s, amount) = do
      most <- Node.node amount >>= integer >>= natural n
      Right (reference', s {TargetSlot.count = printed 1 most})
    permanents' f = do
      (amount, what) <- pair n
      s <- permanentSlot context what
      f (s, amount)

-- | Each target's reference, numbered where several share one
-- ("Ref_TargetPermanent1"), and its slot: "target" for the only one.
slotNames :: [String] -> [(String, SlotName.SlotName)]
slotNames refs =
  let suffixed = case refs of
        [only] -> [(only, "target")]
        _ -> zipWith (\i r -> (if length (filter (== r) refs) > 1 then r <> show (occurrence i r) else r, "target" <> show (i + 1 :: Int))) [0 ..] refs
      occurrence i r = length (filter (== r) (take (i + 1) refs))
   in fmap (\(r, s) -> (r, SlotName.MkSlotName (Text.pack s))) suffixed

-- | The instructions as clauses: consecutive mandatory ones in one, and an
-- optional one (CR 603.5's "you may") in a clause of its own.
clauses :: Context -> [Value.Value] -> Translated [Clause]
clauses context actions = do
  nodes <- traverse Node.node actions
  cs <- steps nodes
  pure (List.foldr gather [] cs)
  where
    steps ns = case ns of
      [] -> Right []
      -- "You may pay [cost]. If you do, [instructions]" (CR 118.12).
      may : gate : rest
        | Node.tag may == "MayCost",
          Node.tag gate == "If" -> do
            price <- Node.argument may >>= costOf
            (condition', body) <- pair gate
            paid <- Node.node condition'
            Monad.unless (Node.tag paid == "CostWasPaid") (Node.untranslated paid)
            es <- Common.asArray body >>= traverse (Node.node Monad.>=> effects context)
            let gated = (clause Optionality.Mandatory (concat es)) {Clause.payGate = Just (payGate price)}
            fmap (gated :) (steps rest)
      n : rest -> do
        c <- step n
        fmap (c :) (steps rest)
    step n = case Node.tag n of
      "MayAction" -> do
        inner <- Node.child n
        fmap (clause (Optionality.Optional (PlayerRef.Relative PlayerRelation.You))) (effects context inner)
      _ -> fmap (clause Optionality.Mandatory) (effects context n)
    plain c = Clause.optionality c == Optionality.Mandatory && Maybe.isNothing (Clause.payGate c)
    gather c rest = case rest of
      d : ds | plain c && plain d -> c {Clause.effects = Clause.effects c <> Clause.effects d} : ds
      _ -> c : rest

-- | A cost you may pay for what follows to happen (CR 118.12).
payGate :: Cost.Cost Keyword.Keyword -> PayGate.PayGate
payGate price =
  PayGate.MkPayGate
    { PayGate.payer = PlayerRef.InSlot Oracle.Target.youSlot,
      PayGate.cost = CostChoice.MkCostChoice (price NonEmpty.:| []),
      PayGate.basis = Nothing,
      PayGate.branch = PayBranch.IfPaid,
      PayGate.obligation = PayObligation.Optional,
      PayGate.perEach = Nothing,
      PayGate.offeredAt = Nothing
    }

clause :: Optionality.Optionality -> [Effect] -> Clause
clause optionality es =
  Clause.MkClause
    { Clause.ifTaken = Nothing,
      Clause.condition = Nothing,
      Clause.orElse = Nothing,
      Clause.optionality = optionality,
      Clause.payGate = Nothing,
      Clause.effects = Seq.fromList es
    }

-- | One instruction's effects.
effects :: Context -> Node.Node -> Translated [Effect]
effects context n = case Node.tag n of
  "SpellDealsDistributedDamage" -> do
    s <- Node.child n
    Monad.unless (Node.tag s == "ThisSpell") (Node.untranslated s)
    case dividing context of
      Just name -> pure [Effect.DealDamage DealDamage.MkDealDamage {DealDamage.parts = Seq.singleton (DamagePart.MkDamagePart (ObjectRef.InSlot name) (Quantity.Share name)), DealDamage.dealer = Nothing, DealDamage.excess = Nothing, DealDamage.tally = Nothing}]
      Nothing -> Node.untranslated n
  "SpellDealsDamage" -> do
    (source, amount, recipient) <- triple n
    s <- Node.node source
    Monad.unless (Node.tag s == "ThisSpell") (Node.untranslated s)
    damage Nothing amount recipient
  "PermanentDealsDamage" -> do
    (source, amount, recipient) <- triple n
    dealer <- permanent context source
    case dealer of
      ObjectRef.InSlot s | s == Oracle.Target.selfSlot -> damage Nothing amount recipient
      ObjectRef.InSlot s -> damage (Just s) amount recipient
      _ -> Node.untranslated n
  "PlayerAction" -> do
    (who, action) <- pair n
    p <- player context who
    Node.node action >>= playerEffects context p
  "EachPlayerAction" -> do
    (who, action) <- pair n
    relation <- players who
    Node.node action >>= playerEffects context {actor = Just PlayerRef.Candidate} (PlayerRef.Relative relation)
  "DestroyPermanent" -> destroy Regenerability.Regenerable =<< (Node.argument n >>= permanent context)
  "DestroyPermanentNoRegen" -> destroy Regenerability.CantBeRegenerated =<< (Node.argument n >>= permanent context)
  "DestroyEachPermanent" -> destroy Regenerability.Regenerable =<< (Node.argument n >>= group context)
  "DestroyEachPermanentNoRegen" -> destroy Regenerability.CantBeRegenerated =<< (Node.argument n >>= group context)
  "PutEachPermanentIntoItsOwnersHand" -> move Zone.Hand =<< (Node.argument n >>= group context)
  "PutPermanentOnTopOfOwnersLibrary" -> do
    ref <- Node.argument n >>= permanent context
    pure [Effect.MoveToZone (moveTo Zone.Library ref) {MoveToZone.placement = LibraryPlacement.Stated LibraryPosition.Top}]
  "CounterSpell" -> do
    ref <- Node.argument n >>= spellRef context
    pure [Effect.Counter Counter.MkCounter {Counter.ref = ref, Counter.slot = Nothing, Counter.sources = Nothing, Counter.instead = Nothing}]
  "AddMana" -> do
    produced <- Node.child n >>= productions context
    pure [Effect.AddMana (addition p) | p <- produced]
  "PutPermanentIntoItsOwnersHand" -> move Zone.Hand =<< (Node.argument n >>= permanent context)
  "PutGraveyardCardIntoHand" -> move Zone.Hand =<< (Node.argument n >>= graveyardCard context)
  "Exile" -> do
    (what, riders) <- pair n
    Common.asArray riders >>= \rs -> Monad.unless (null rs) (Node.untranslated n)
    exilables <- Common.asArray what >>= traverse Node.node
    case exilables of
      [e] | Node.tag e == "Permanent" -> move Zone.Exile =<< (Node.argument e >>= permanent context)
      _ -> Node.untranslated n
  "CreatePermanentLayerEffectUntil" -> do
    (who, changes, until') <- triple n
    ref <- permanent context who
    modify ref changes until'
  "CreateEachPermanentLayerEffectUntil" -> do
    (who, changes, until') <- triple n
    ref <- group context who
    modify ref changes until'
  "TapPermanent" -> fmap (pure . Effect.Tap) (Node.argument n >>= permanent context)
  "UntapPermanent" -> fmap (pure . Effect.Untap) (Node.argument n >>= permanent context)
  "TapEachPermanent" -> fmap (pure . Effect.Tap) (Node.argument n >>= group context)
  "UntapEachPermanent" -> fmap (pure . Effect.Untap) (Node.argument n >>= group context)
  "SacrificePermanent" -> do
    ref <- Node.argument n >>= permanent context
    Monad.unless (ref == ObjectRef.InSlot Oracle.Target.selfSlot) (Node.untranslated n)
    pure [Effect.Sacrifice (SacrificeEffect.MkSacrificeEffect ref Sacrificer.EffectController Nothing)]
  -- A shield used up by the next destruction it replaces this turn (CR
  -- 701.19a), of the source or of the object a slot holds. Any other
  -- permanent -- Regeneration's "enchanted creature" -- is bound by a loop as
  -- the instruction resolves, so the shield names the permanent it named then
  -- rather than re-reading the reference.
  "RegeneratePermanent" -> do
    ref <- Node.argument n >>= permanent context
    let shield matching = Effect.Replace Replace.MkReplace {Replace.duration = Duration.UntilEndOfTurn, Replace.uses = Uses.Once, Replace.origin = ReplacementOrigin.Other, Replace.condition = Nothing, Replace.effect = ReplacementEffect.DestructionR DestructionR.MkDestructionR {DestructionR.matching = matching, DestructionR.rewrite = DestructionRewrite.Regenerate}}
        regenerated = SlotName.MkSlotName (Text.pack "regenerated")
    pure $ case ref of
      ObjectRef.InSlot s
        | s == Oracle.Target.selfSlot -> [shield Nothing]
        | otherwise -> [shield (Just (Filter.IsBound s))]
      _ -> [Effect.ForEach ForEach.MkForEach {ForEach.ref = ref, ForEach.members = LoopMembers.Every, ForEach.slot = regenerated, ForEach.body = Seq.singleton (shield (Just (Filter.IsBound regenerated))), ForEach.individually = False, ForEach.payGate = Nothing, ForEach.startingWith = Nothing}]
  "PutCounters" -> do
    actions <- Node.arguments n >>= traverse Node.node
    fmap concat (traverse (counters context) actions)
  _ -> playerEffects context (PlayerRef.Relative PlayerRelation.You) n
  where
    damage dealer amount recipient = do
      q <- quantity context amount
      r <- Node.node recipient
      refs <- case Node.tag r of
        "MultipleRecipients" -> Node.arguments r >>= traverse (damageRecipient context)
        _ -> fmap pure (damageRecipient context recipient)
      pure [Effect.DealDamage DealDamage.MkDealDamage {DealDamage.parts = Seq.fromList (fmap (\ref -> DamagePart.MkDamagePart ref q) refs), DealDamage.dealer = dealer, DealDamage.excess = Nothing, DealDamage.tally = Nothing}]
    destroy regenerability ref = pure [Effect.Destroy Destroy.MkDestroy {Destroy.ref = ref, Destroy.regenerability = regenerability, Destroy.slot = Nothing, Destroy.buried = Nothing, Destroy.permanents = Nothing}]
    move zone ref = pure [Effect.MoveToZone (moveTo zone ref)]
    modify ref changes until' = do
      duration <- Node.node until' >>= expiration
      ms <- Common.asArray changes >>= traverse (Node.node Monad.>=> staticModification)
      pure [Effect.ModifyTarget ModifyTarget.MkModifyTarget {ModifyTarget.duration = duration, ModifyTarget.modification = m, ModifyTarget.ref = ref, ModifyTarget.each = Nothing} | m <- concat ms]

-- | An instruction a player follows: "you", or the player named.
playerEffects :: Context -> PlayerRef.PlayerRef -> Node.Node -> Translated [Effect]
playerEffects context who n = case Node.tag n of
  "DrawACard" -> draw (Quantity.Literal 1)
  "DrawNumberCards" -> draw =<< (Node.argument n >>= quantity context)
  "GainLife" -> do
    q <- Node.argument n >>= quantity context
    pure [Effect.GainLife (PlayerQuantity.MkPlayerQuantity who q)]
  "LoseLife" -> do
    q <- Node.argument n >>= quantity context
    pure [Effect.LoseLife LifeLoss.MkLifeLoss {LifeLoss.player = who, LifeLoss.quantity = q, LifeLoss.cause = LifeLossCause.ByEffect, LifeLoss.tally = Nothing}]
  "DiscardACard" -> discard (Quantity.Literal 1)
  "DiscardNumberCardsAtRandom" -> do
    q <- Node.argument n >>= quantity context
    pure [Effect.Discard (Discard.These TheseDiscard.MkTheseDiscard {TheseDiscard.cards = ObjectRef.RandomCardInHand RandomCardInHand.MkRandomCardInHand {RandomCardInHand.player = who, RandomCardInHand.filter = Filter.And [], RandomCardInHand.count = q}, TheseDiscard.discarded = Nothing})]
  "GainLifeForEach" -> do
    q <- forEach
    pure [Effect.GainLife (PlayerQuantity.MkPlayerQuantity who q)]
  "LoseLifeForEach" -> do
    q <- forEach
    pure [Effect.LoseLife LifeLoss.MkLifeLoss {LifeLoss.player = who, LifeLoss.quantity = q, LifeLoss.cause = LifeLossCause.ByEffect, LifeLoss.tally = Nothing}]
  "DiscardNumberCards" -> discard =<< (Node.argument n >>= quantity context)
  "MillNumberCards" -> do
    q <- Node.argument n >>= quantity context
    pure [Effect.Mill Mill.MkMill {Mill.player = who, Mill.quantity = q, Mill.tally = Nothing, Mill.slot = Nothing}]
  "SearchLibrary" -> do
    steps <- Node.arguments n >>= traverse Node.node
    fmap pure (searchLibrary who steps)
  "CreateTokens" -> do
    (tokensValue, riders) <- pair n
    Common.asArray riders >>= \rs -> Monad.unless (null rs) (Node.untranslated n)
    tokens <- Common.asArray tokensValue >>= traverse (Node.node Monad.>=> creatable context)
    pure [Effect.Create Create.MkCreate {Create.quantity = q, Create.card = c, Create.riders = EntryRiders.defaultValue, Create.slot = Nothing, Create.creator = who} | (q, c) <- tokens]
  _ -> Node.untranslated n
  where
    draw q = pure [Effect.Draw Draw.MkDraw {Draw.player = who, Draw.quantity = q, Draw.slot = Nothing}]
    -- So much for each object counted (CR 608.2h).
    forEach = do
      (each, counted) <- pair n
      k <- Node.node each >>= integer
      factor <- natural n k
      c <- quantity context counted
      case (factor, c) of
        (1, Quantity.Count _) -> Right c
        (_, Quantity.Count _) | factor > 1 -> Right (Quantity.Arithmetic (Arithmetic.Times (Times.MkTimes factor c)))
        _ -> Node.untranslated n
    discard q = pure [Effect.Discard (Discard.Counted CountedDiscard.MkCountedDiscard {CountedDiscard.player = who, CountedDiscard.quantity = q, CountedDiscard.discarded = Nothing})]

moveTo :: Zone.Zone -> ObjectRef.ObjectRef -> MoveToZone.MoveToZone Ability
moveTo zone ref =
  MoveToZone.MkMoveToZone
    { MoveToZone.ref = ref,
      MoveToZone.zone = zone,
      MoveToZone.riders = EntryRiders.defaultValue,
      MoveToZone.slot = Nothing,
      MoveToZone.origin = Nothing,
      MoveToZone.placement = LibraryPlacement.defaultValue,
      MoveToZone.duration = Nothing
    }

-- | A player's search of their library for one card (CR 701.23a), and where
-- the card goes, after which the library is shuffled (CR 701.24b): the
-- destination's shuffle, Parun.Types.SearchDestination's.
searchLibrary :: PlayerRef.PlayerRef -> [Node.Node] -> Translated Effect
searchLibrary who steps = case steps of
  find : rest -> do
    f <- case Node.tag find of
      "FindAGenericCard" -> Right (Filter.And [])
      "FindACardOfType" -> Node.child find >>= spellFilter
      _ -> Node.untranslated find
    destination <- case fmap Node.tag rest of
      ["PutFoundCardsIntoHand", "Shuffle"] -> Right SearchDestination.Hand
      ["RevealFoundCards", "PutFoundCardsIntoHand", "Shuffle"] -> Right SearchDestination.RevealThenHand
      ["PutFoundCardsOntoBattlefield", "Shuffle"] | (onto : _) <- rest -> do
        flags <- Node.argument onto >>= Common.asArray >>= traverse Node.node
        case fmap Node.tag flags of
          ["EntersNormally"] -> Right SearchDestination.Battlefield
          ["EntersTapped"] -> Right SearchDestination.BattlefieldTapped
          _ -> Node.untranslated onto
      ["SetAsideFoundCards", "Shuffle", "PutSetAsideCardsOnTopOfLibrary"] -> Right SearchDestination.Top
      ["RevealFoundCards", "SetAsideFoundCards", "Shuffle", "PutSetAsideCardsOnTopOfLibrary"] -> Right SearchDestination.RevealThenTop
      _ -> maybe (Node.untranslated find) Node.untranslated (Maybe.listToMaybe rest)
    Right
      ( Effect.Search
          Search.MkSearch
            { Search.searcher = who,
              Search.owner = who,
              Search.zones = Set.singleton Zone.Library,
              Search.outsideTheGame = False,
              Search.quantity = Just (Quantity.Literal 1),
              Search.filter = f,
              Search.upTo = False,
              Search.destination = destination,
              Search.subject = Nothing,
              Search.slot = Nothing,
              Search.differentIn = Set.empty,
              Search.exactly = False,
              Search.andOr = False
            }
      )
  [] -> Left (Text.pack "_Action:SearchLibrary")

addition :: ManaProduction.ManaProduction -> ManaAddition.ManaAddition
addition p =
  ManaAddition.MkManaAddition
    { ManaAddition.player = PlayerRef.Relative PlayerRelation.You,
      ManaAddition.production = p,
      ManaAddition.count = Quantity.Literal 1,
      ManaAddition.retention = ManaRetention.Ordinary,
      ManaAddition.restriction = Nothing,
      ManaAddition.rider = Nothing,
      ManaAddition.whenSpent = Nothing
    }

-- | Mana an instruction adds (CR 106.1), one addition per mana symbol, and
-- of an "or" the kind the mode chooses.
productions :: Context -> Node.Node -> Translated [ManaProduction.ManaProduction]
productions context n = case Node.tag n of
  "And" -> fmap concat (Node.arguments n >>= traverse (Node.node Monad.>=> productions context))
  "Or" -> do
    options <- Node.arguments n
    case manaChoice context of
      Just i | (option : _) <- drop i options -> Node.node option >>= productions context
      _ -> Node.untranslated n
  "AnyManaColor" -> Right [ManaProduction.AnyColor]
  'M' : 'a' : 'n' : 'a' : 'P' : 'r' : 'o' : 'd' : 'u' : 'c' : 'e' : [c] | Just t <- Ingest.manaType c -> Right [ManaProduction.OfType t]
  _ -> Node.untranslated n

-- | How long a created effect lasts (CR 611.2a).
expiration :: Node.Node -> Translated Duration.Duration
expiration n = case Node.tag n of
  "UntilEndOfTurn" -> Right Duration.UntilEndOfTurn
  _ -> Node.untranslated n

-- | Counters put on objects (CR 122.1).
counters :: Context -> Node.Node -> Translated [Effect]
counters context n = case Node.tag n of
  "ACounterOfTypeOnPermanent" -> do
    (k, who) <- pair n
    put (Quantity.Literal 1) k =<< permanent context who
  "NumberCountersOfTypeOnPermanent" -> do
    (amount, k, who) <- triple n
    q <- quantity context amount
    put q k =<< permanent context who
  "ACounterOfTypeOnEachPermanent" -> do
    (k, who) <- pair n
    put (Quantity.Literal 1) k =<< group context who
  _ -> Node.untranslated n
  where
    put q k ref = do
      kind <- Node.node k >>= counterKind
      pure [Effect.PutCounters PutCounters.MkPutCounters {PutCounters.kind = kind, PutCounters.quantity = q, PutCounters.ref = ref}]

counterKind :: Node.Node -> Translated (CounterKind.CounterKind Keyword.Keyword)
counterKind n = case Node.tag n of
  "PTCounter" -> do
    (p, t) <- pair n
    power <- number n p
    toughness <- number n t
    Right $ case (power, toughness) of
      (1, 1) -> CounterKind.PlusOnePlusOne
      (-1, -1) -> CounterKind.MinusOneMinusOne
      _ -> CounterKind.UnsafePowerToughness power toughness
  _ -> Node.untranslated n

-- | Tokens an instruction creates (CR 111.1): how many, and the card each is.
creatable :: Context -> Node.Node -> Translated (Quantity.Quantity, Card.Card)
creatable context n = case Node.tag n of
  "NumberTokens" -> do
    (amount, inner) <- pair n
    q <- quantity context amount
    (_, c) <- Node.node inner >>= creatable context
    Right (q, c)
  "TokenWithPT" -> do
    as <- Node.arguments n
    case as of
      [ptValue, coloursValue, supertypesValue, typesValue, subtypesValue, rulesValue] -> do
        pt <- Node.node ptValue
        (p, t) <- pair pt
        power <- Common.asInteger p
        toughness <- Common.asInteger t
        colours <- Node.node coloursValue >>= tokenColours
        supertypes <- Common.asArray supertypesValue
        Monad.unless (null supertypes) (Node.untranslated n)
        types <- Common.asArray typesValue >>= traverse Common.asText >>= traverse (Ingest.enumWord "type")
        subtypesNode <- Node.node subtypesValue
        subtypeNames <- case Node.tag subtypesNode of
          "SubtypesList" -> Node.arguments subtypesNode >>= traverse Common.asText
          _ -> Node.untranslated subtypesNode
        subtypes <- traverse (Ingest.enumWord "subtype") subtypeNames
        keywords <- Common.asArray rulesValue >>= traverse (Node.node Monad.>=> keywordRule)
        let line = TypeLine.MkTypeLine Set.empty (Set.fromList types) (Set.fromList (subtypes :: [Subtype.Subtype]))
            name = CardName.MkCardName (Text.unwords (subtypeNames <> [Text.pack "Token"]))
            face = Oracle.Face.bare name Nothing Nothing (Set.fromList colours) line (Just (Power.MkPower (Quantity.Literal power))) (Just (Toughness.MkToughness (Quantity.Literal toughness))) (Map.fromListWith (+) (fmap (\k -> (k, 1)) keywords))
        Right (Quantity.Literal 1, Card.MkCard Layout.Normal (face NonEmpty.:| []))
      _ -> Node.untranslated n
  _ -> Node.untranslated n

tokenColours :: Node.Node -> Translated [Color.Color]
tokenColours n = case Node.tag n of
  "Colorless" -> Right []
  "Colors" -> Node.arguments n >>= traverse Common.asText >>= traverse (Ingest.enumWord "color")
  _ -> Node.untranslated n

-- References ------------------------------------------------------------------

-- | One permanent an instruction names: the source, a target, or an object
-- its trigger event names.
permanent :: Context -> Value.Value -> Translated ObjectRef.ObjectRef
permanent context value = do
  n <- Node.node value
  case Node.tag n of
    "ThisPermanent" -> Right (ObjectRef.InSlot Oracle.Target.selfSlot)
    -- What the source is attached to (CR 303.4b, CR 301.5a).
    "HostPermanent" -> Right (ObjectRef.EachMatching Filter.IsHostOfSource)
    t
      | Just s <- Map.lookup t (references context) -> Right (ObjectRef.InSlot s)
      | Just s <- Map.lookup t (bindings context) -> Right (ObjectRef.InSlot s)
    _ -> Node.untranslated n

-- | Several permanents an instruction names: the targets of a slot, or
-- every permanent of a description (CR 109.2).
group :: Context -> Value.Value -> Translated ObjectRef.ObjectRef
group context value = do
  n <- Node.node value
  case Map.lookup (Node.tag n) (references context) of
    Just s -> Right (ObjectRef.InSlot s)
    Nothing -> fmap ObjectRef.EachMatching (permanents context value)

-- | A card in a graveyard a target names.
graveyardCard :: Context -> Value.Value -> Translated ObjectRef.ObjectRef
graveyardCard = permanent

-- | A spell a target names.
spellRef :: Context -> Value.Value -> Translated ObjectRef.ObjectRef
spellRef = permanent

-- | One player an instruction names.
player :: Context -> Value.Value -> Translated PlayerRef.PlayerRef
player context value = do
  n <- Node.node value
  case Node.tag n of
    "You" -> Right (PlayerRef.Relative PlayerRelation.You)
    "ActionPlayer" | Just p <- actor context -> Right p
    "ControllerOfPermanent" -> do
      ref <- Node.argument n >>= permanent context
      case ref of
        ObjectRef.InSlot s | s /= Oracle.Target.selfSlot -> Right (PlayerRef.ControllerOfBound s)
        _ -> Node.untranslated n
    t
      | Just s <- Map.lookup t (references context) -> Right (PlayerRef.InSlot s)
      | Just s <- Map.lookup t (bindings context) -> Right (PlayerRef.InSlot s)
    _ -> Node.untranslated n

-- | What is dealt damage (CR 120.1): something a slot names, you, or each
-- permanent or player of a group.
damageRecipient :: Context -> Value.Value -> Translated ObjectRef.ObjectRef
damageRecipient context value = do
  n <- Node.node value
  case Node.tag n of
    "Permanent" -> Node.argument n >>= permanent context
    "Player" -> do
      p <- Node.argument n >>= player context
      case p of
        PlayerRef.Relative PlayerRelation.You -> Right (ObjectRef.InSlot Oracle.Target.youSlot)
        PlayerRef.InSlot s -> Right (ObjectRef.InSlot s)
        _ -> Node.untranslated n
    "EachPermanent" -> Node.argument n >>= group context
    "EachPlayer" -> do
      relation <- Node.argument n >>= players
      case relation of
        PlayerRelation.AnyPlayer -> Right ObjectRef.EachPlayer
        PlayerRelation.Opponent -> Right ObjectRef.EachOpponent
        _ -> Node.untranslated n
    t | Just s <- Map.lookup t (references context) -> Right (ObjectRef.InSlot s)
    _ -> Node.untranslated n

-- | A number (CR 107.1): printed, X (CR 107.3), a count of permanents (CR
-- 608.2h), or the source's power.
quantity :: Context -> Value.Value -> Translated Quantity.Quantity
quantity context value = do
  n <- Node.node value
  case Node.tag n of
    "Integer" -> fmap Quantity.Literal (Node.argument n >>= Common.asInteger)
    "ValueX" -> Right (Quantity.InSlot Oracle.Target.xSlot)
    "TheNumberOfPermanentsOnTheBattlefield" -> do
      f <- Node.argument n >>= permanents context
      Right (Quantity.Count Count.MkCount {Count.scope = Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)), Count.filter = f, Count.aggregation = Aggregation.Members})
    "TheNumberOfCardsInPlayersHand" -> do
      whose <- Node.argument n >>= player context
      Right (Quantity.Count Count.MkCount {Count.scope = Scope.InZone (InZone.MkInZone Zone.Hand whose), Count.filter = Filter.And [], Count.aggregation = Aggregation.Members})
    "TheNumberOfGraveyardCards" -> do
      cards <- Node.child n
      parts <- case Node.tag cards of
        "And" -> Node.arguments cards >>= traverse Node.node
        _ -> Right [cards]
      (whose, rest) <- case List.partition ((== "InAPlayersGraveyard") . Node.tag) parts of
        ([place], rest) -> do
          group' <- Node.child place
          p <- case Node.tag group' of
            "SinglePlayer" -> Node.argument group' >>= player context
            _ -> Node.untranslated group'
          Right (p, rest)
        _ -> Node.untranslated cards
      fs <- traverse spellFilter rest
      Right (Quantity.Count Count.MkCount {Count.scope = Scope.InZone (InZone.MkInZone Zone.Graveyard whose), Count.filter = conjoined fs, Count.aggregation = Aggregation.Members})
    "PowerOfPermanent" -> measured Measure.Power n
    "ToughnessOfPermanent" -> measured Measure.Toughness n
    _ -> Node.untranslated n
  where
    measured m n = do
      ref <- Node.argument n >>= permanent context
      case ref of
        ObjectRef.InSlot s
          | s == Oracle.Target.selfSlot -> Right (Quantity.Measure m)
          | otherwise -> Right (Quantity.AgainstSlot (AgainstSlot.MkAgainstSlot s (Quantity.Measure m)))
        _ -> Node.untranslated n

-- Groups and targets ----------------------------------------------------------

-- | A group of players as the relation it names (CR 102).
players :: Value.Value -> Translated PlayerRelation.PlayerRelation
players value = do
  n <- Node.node value
  case Node.tag n of
    "AnyPlayer" -> Right PlayerRelation.AnyPlayer
    "Opponent" -> Right PlayerRelation.Opponent
    "SinglePlayer" -> do
      p <- Node.child n
      if Node.tag p == "You" then Right PlayerRelation.You else Node.untranslated p
    _ -> Node.untranslated n

-- | A description of permanents as the filter it means (CR 109.2), its
-- conjunctions flattened.
permanents :: Context -> Value.Value -> Translated Filter
permanents context value = do
  n <- Node.node value
  fmap conjoined (conjunction context n)

conjunction :: Context -> Node.Node -> Translated [Filter]
conjunction context n = case Node.tag n of
  "And" -> fmap concat (Node.arguments n >>= traverse (Node.node Monad.>=> conjunction context))
  "AnyPermanent" -> Right []
  _ -> fmap pure (atom context n)

atom :: Context -> Node.Node -> Translated Filter
atom context n = case Node.tag n of
  "IsCardtype" -> cardType Filter.HasCardType
  "IsNonCardtype" -> cardType (Filter.Not . Filter.HasCardType)
  "IsColor" -> fmap Filter.HasColor (Node.child n >>= colour)
  "IsNonColor" -> fmap (Filter.Not . Filter.HasColor) (Node.child n >>= colour)
  "IsCreatureType" -> subtype Filter.HasSubtype
  "IsLandType" -> subtype Filter.HasSubtype
  "IsArtifactType" -> subtype Filter.HasSubtype
  "IsEnchantmentType" -> subtype Filter.HasSubtype
  "IsNonCreatureType" -> subtype (Filter.Not . Filter.HasSubtype)
  "IsSupertype" -> supertype Filter.HasSupertype
  "IsNonSupertype" -> supertype (Filter.Not . Filter.HasSupertype)
  "ControlledByAPlayer" -> do
    who <- Node.child n
    case (Node.tag who, fmap Node.node (Node.args who)) of
      ("SinglePlayer", Just (Right p)) | Just s <- Map.lookup (Node.tag p) (references context) -> Right (Filter.ControlledByBound s)
      _ -> fmap Filter.ControlledBy (Node.argument n >>= players)
  -- "Another": other than the source, or than an object a slot names.
  "Other" -> do
    ref <- Node.argument n >>= permanent context
    case ref of
      ObjectRef.InSlot s
        | s == Oracle.Target.selfSlot -> Right (Filter.Not Filter.IsSource)
        | elem s (Map.elems (references context)) -> Right (Filter.Not (Filter.IsBound s))
      _ -> Node.untranslated n
  "IsAttacking" -> Right Filter.IsAttacking
  "IsBlocking" -> Right Filter.IsBlocking
  "IsTapped" -> Right Filter.IsTapped
  "IsUntapped" -> Right (Filter.Not Filter.IsTapped)
  "IsToken" -> Right Filter.IsToken
  "IsNonToken" -> Right (Filter.Not Filter.IsToken)
  "HasAbility" -> fmap Filter.HasKeyword (Node.child n >>= keywordRule)
  "DoesntHaveAbility" -> fmap (Filter.Not . Filter.HasKeyword) (Node.child n >>= keywordRule)
  "Or" -> do
    disjuncts <- Node.arguments n >>= traverse (permanents context)
    Right (Filter.Or disjuncts)
  _ -> Node.untranslated n
  where
    word = Node.argument n >>= Common.asText
    cardType f = fmap f (word >>= Ingest.enumWord "type")
    subtype f = fmap f (word >>= Ingest.enumWord "subtype")
    supertype f = fmap f (word >>= Ingest.enumWord "supertype")

-- | A target (CR 115.1) as the reference its instructions name it by and the
-- slot it is chosen for.
target :: Context -> Node.Node -> Translated TargetSlot.TargetSlot
target context n = case Node.tag n of
  "AnyTarget" -> Right (slot Pool.AnyTarget Nothing)
  "TargetPermanent" -> Node.argument n >>= permanentSlot context
  "UptoOneTargetPermanent" -> fmap (\s -> s {TargetSlot.count = printed 0 1}) (Node.argument n >>= permanentSlot context)
  "NumberTargetPermanents" -> counted True
  "UptoNumberTargetPermanents" -> counted False
  "OneOrTwoTargetPermanents" -> fmap (\s -> s {TargetSlot.count = printed 1 2}) (Node.argument n >>= permanentSlot context)
  "TargetPlayer" -> do
    relation <- Node.argument n >>= players
    filter' <- case relation of
      PlayerRelation.AnyPlayer -> Right Nothing
      PlayerRelation.Opponent -> Right (Just (Filter.IsPlayer PlayerRelation.Opponent))
      _ -> Node.untranslated n
    Right (slot Pool.Players filter')
  "TargetSpell" -> do
    f <- Node.argument n >>= spells
    Right (slot Pool.Spells f)
  "TargetGraveyardCard" -> do
    (scope, f) <- Node.argument n >>= graveyardCards
    Right (slot (Pool.CardsInGraveyard scope) f)
  "TargetPlayerOrPermanent" -> do
    (who, what) <- pair n
    relation <- players who
    f <- permanents context what
    case (relation, f) of
      (PlayerRelation.AnyPlayer, Filter.HasCardType CardType.Planeswalker) -> Right (slot Pool.PlayersAndPlaneswalkers Nothing)
      (PlayerRelation.Opponent, Filter.HasCardType CardType.Planeswalker) -> Right (slot Pool.AnyTarget (Just (Filter.Or [Filter.IsPlayer PlayerRelation.Opponent, Filter.HasCardType CardType.Planeswalker])))
      _ -> Node.untranslated n
  _ -> Node.untranslated n
  where
    counted exactly = do
      (amount, what) <- pair n
      k <- Node.node amount >>= integer
      most <- natural n k
      s <- permanentSlot context what
      Monad.when (most < 2) (Node.untranslated n)
      Right s {TargetSlot.count = printed (if exactly then most else 0) most}

-- | The reference a target's instructions name it by, before any numbering.
reference :: Node.Node -> Translated String
reference n = case Node.tag n of
  "AnyTarget" -> Right "Ref_AnyTarget"
  "TargetPermanent" -> Right "Ref_TargetPermanent"
  "UptoOneTargetPermanent" -> Right "Ref_TargetPermanent"
  "NumberTargetPermanents" -> Right "Ref_TargetPermanents"
  "UptoNumberTargetPermanents" -> Right "Ref_TargetPermanents"
  "OneOrTwoTargetPermanents" -> Right "Ref_TargetPermanents"
  "TargetPlayer" -> Right "Ref_TargetPlayer"
  "TargetSpell" -> Right "Ref_TargetSpell"
  "TargetGraveyardCard" -> Right "Ref_TargetGraveyardCard"
  "TargetPlayerOrPermanent" -> Right "Ref_TargetPlayerOrPermanent"
  _ -> Node.untranslated n

printed :: Natural.Natural -> Natural.Natural -> SlotCount.SlotCount
printed least most = SlotCount.Printed (TargetCount.MkTargetCount least (Just most))

slot :: Pool.Pool -> Maybe Filter -> TargetSlot.TargetSlot
slot pool f =
  TargetSlot.MkTargetSlot
    { TargetSlot.pool = pool,
      TargetSlot.filter = f,
      TargetSlot.count = printed 1 1,
      TargetSlot.amount = Nothing,
      TargetSlot.chooser = Nothing,
      TargetSlot.perPlayer = Nothing,
      TargetSlot.divided = Nothing,
      TargetSlot.together = Nothing
    }

-- | A slot of permanents: creatures (CR 109.2) where the description says
-- "creature", and permanents otherwise.
permanentSlot :: Context -> Value.Value -> Translated TargetSlot.TargetSlot
permanentSlot context value = do
  fs <- Node.node value >>= conjunction context
  let creature = Filter.HasCardType CardType.Creature
      described gs = case gs of
        [] -> Nothing
        _ -> Just (conjoined gs)
  Right $
    if elem creature fs
      then slot Pool.Creatures (described (filter (/= creature) fs))
      else slot Pool.Permanents (described fs)

-- | A description of spells (CR 112.1).
spells :: Value.Value -> Translated (Maybe Filter)
spells value = do
  n <- Node.node value
  case Node.tag n of
    "AnySpell" -> Right Nothing
    _ -> fmap Just (spellFilter n)

-- | A description of spells or cards by their characteristics: card types,
-- colours, supertypes and subtypes (CR 205).
spellFilter :: Node.Node -> Translated Filter
spellFilter n = case Node.tag n of
  "IsCardtype" -> fmap Filter.HasCardType (Node.argument n >>= Common.asText >>= Ingest.enumWord "type")
  "IsNonCardtype" -> fmap (Filter.Not . Filter.HasCardType) (Node.argument n >>= Common.asText >>= Ingest.enumWord "type")
  "IsColor" -> fmap Filter.HasColor (Node.child n >>= colour)
  "IsNonColor" -> fmap (Filter.Not . Filter.HasColor) (Node.child n >>= colour)
  "IsSupertype" -> fmap Filter.HasSupertype (Node.argument n >>= Common.asText >>= Ingest.enumWord "supertype")
  "IsCreatureType" -> subtype
  "IsLandType" -> subtype
  "IsArtifactType" -> subtype
  "IsEnchantmentType" -> subtype
  "And" -> fmap Filter.And (Node.arguments n >>= traverse (Node.node Monad.>=> spellFilter))
  "Or" -> fmap Filter.Or (Node.arguments n >>= traverse (Node.node Monad.>=> spellFilter))
  _ -> Node.untranslated n
  where
    subtype = fmap Filter.HasSubtype (Node.argument n >>= Common.asText >>= Ingest.enumWord "subtype")

-- | A description of cards in graveyards: whose graveyards (CR 404.1), and
-- what else the cards are.
graveyardCards :: Value.Value -> Translated (ZoneScope.ZoneScope, Maybe Filter)
graveyardCards value = do
  n <- Node.node value
  parts <- case Node.tag n of
    "And" -> Node.arguments n >>= traverse Node.node
    _ -> Right [n]
  let (places, rest) = List.partition (\p -> elem (Node.tag p) ["InAPlayersGraveyard", "AnyCardInAnyGraveyard"]) parts
  scope <- case places of
    [p] | Node.tag p == "InAPlayersGraveyard" -> fmap (ZoneScope.Scoped . PlayerScope.Related) (Node.argument p >>= players)
    [p] -> Right (ZoneScope.Scoped (PlayerScope.Related PlayerRelation.AnyPlayer)) <* Right p
    _ -> Node.untranslated n
  fs <- traverse spellFilter rest
  Right
    ( scope,
      case fs of
        [] -> Nothing
        [f] -> Just f
        _ -> Just (Filter.And fs)
    )
