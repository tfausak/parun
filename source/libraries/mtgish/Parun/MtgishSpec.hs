-- Covers Parun.Mtgish and Parun.Mtgish.Node on small committed mtgish ASTs,
-- each a line of mtgish's data/mtgish.lines.json (MIT) with its card's
-- Oracle text from MTGJSON.
module Parun.MtgishSpec where

import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.Functor as Functor
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Mtgish as Mtgish
import qualified Parun.Mtgish.Node as Node
import qualified Parun.Oracle.Keyword as Oracle.Keyword
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActivatedAbility as ActivatedAbility
import qualified Parun.Types.ActivationRestriction as ActivationRestriction
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.Card as Card
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
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.CostModifier as CostModifier
import qualified Parun.Types.Count as Count
import qualified Parun.Types.DestructionR as DestructionR
import qualified Parun.Types.DestructionRewrite as DestructionRewrite
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.EntryR as EntryR
import qualified Parun.Types.EntryRewrite as EntryRewrite
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ForEach as ForEach
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Hop as Hop
import qualified Parun.Types.Hybrid as Hybrid
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PayBranch as PayBranch
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerQuantity as PlayerQuantity
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Types.Pool as Pool
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Replace as Replace
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.RuleAbilities as RuleAbilities
import qualified Parun.Types.Sacrifice as Sacrifice
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
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Uses as Uses
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Mtgish" $ do
  Spec.it s "reads a node's family, constructor and arguments" $ do
    Spec.assertEq s (Right (Node.MkNode "Action" "DrawACard" Nothing)) (Common.parse (Text.pack "{\"_Action\":\"DrawACard\"}") >>= Node.node)
    Spec.assertEq s (Left (Text.pack "_Action:DrawACard")) (Common.parse (Text.pack "{\"_Action\":\"DrawACard\"}") >>= Node.node >>= Node.untranslated :: Either Text.Text ())

  Spec.it s "accepts a translation that renders back to its Oracle text" $ do
    Spec.assertEq s (Right ()) (accepts shock)
    Spec.assertEq s (Right ()) (accepts giantGrowth)

  Spec.it s "rejects a translation whose rendering is not its Oracle text" $ do
    Spec.assertEq s (Left (Text.pack "renders as: Shock deals 2 damage to any target.")) (accepts (fst shock, "Shock deals 3 damage to any target."))

  -- A node not translated rejects the whole card, never only its ability:
  -- Index is nothing but the look at the top of its library it stops at.
  Spec.it s "rejects a card at the first node it does not translate" $ do
    Spec.assertEq s (Left (Text.pack "_Action:LookAtTheTopNumberCardsOfLibrary")) (accepts index)

  -- CR 701.17a: "Target player mills two cards."
  Spec.it s "reads milling" $ do
    Spec.assertEq s (Right ()) (accepts millstone)
    Spec.assertEq s [Quantity.Literal 2] [Mill.quantity m | Effect.Mill m <- activatedEffects (translated millstone)]

  -- CR 602.5: "Activate only ..." as the ability's restrictions.
  Spec.it s "reads the restrictions on activating an ability" $ do
    Spec.assertEq s (Right ()) (accepts spittingDrake)
    Spec.assertEq s (Right ()) (accepts vampireBats)
    Spec.assertEq s (Right ()) (accepts disruptingScepter)
    Spec.assertEq s [[ActivationRestriction.TimesEachTurn 1]] (fmap ActivatedAbility.restrictions (Face.activatedAbilities (translated spittingDrake)))
    Spec.assertEq s [[ActivationRestriction.TimesEachTurn 2]] (fmap ActivatedAbility.restrictions (Face.activatedAbilities (translated vampireBats)))
    Spec.assertEq s [[ActivationRestriction.DuringTurn TurnScope.ControllersTurn]] (fmap ActivatedAbility.restrictions (Face.activatedAbilities (translated disruptingScepter)))

  -- CR 701.23a: a search for a card of a description, revealed and put on
  -- top after the shuffle.
  Spec.it s "reads a search of your library" $ do
    Spec.assertEq s (Right ()) (accepts worldlyTutor)
    Spec.assertEq s [(Filter.HasCardType CardType.Creature, SearchDestination.RevealThenTop)] [(Search.filter x, Search.destination x) | Effect.Search x <- spellEffects (translated worldlyTutor)]

  -- CR 508.1c / 509.1b: rules each permanent of a description follows.
  Spec.it s "reads rules on attacking and blocking" $ do
    Spec.assertEq s (Right ()) (accepts lightOfDay)
    let black = AffectedUnless.MkAffectedUnless (Affected.Matching (Filter.And [Filter.HasColor Color.Black, Filter.HasCardType CardType.Creature])) Nothing Nothing Nothing
    Spec.assertEq s [CombatRestriction.CantAttack black, CombatRestriction.CantBlock black] (Face.combatRestrictions (translated lightOfDay))

  -- CR 303.4b: an Aura's instructions name the creature it enchants.
  Spec.it s "reads the host of an Aura in its instructions" $ do
    Spec.assertEq s (Right ()) (accepts firebreathing)
    Spec.assertEq s [ObjectRef.EachMatching Filter.IsHostOfSource] [ModifyTarget.ref m | Effect.ModifyTarget m <- activatedEffects (translated firebreathing)]

  -- CR 601.2f: "Red spells cost {2} more to cast."
  Spec.it s "reads a rule making spells cost more to cast" $ do
    Spec.assertEq s (Right ()) (accepts chill)
    Spec.assertEq s [(PlayerScope.Related PlayerRelation.AnyPlayer, Filter.HasColor Color.Red, CostChange.Increase (ManaCost.MkManaCost [ManaSymbol.Generic 2]))] [(PlayerStaticAbility.scope a, CostModifier.matching m, CostModifier.change m) | a <- Face.playerAbilities (translated chill), PlayerEffect.ModifyCost m <- [PlayerStaticAbility.effect a]]

  -- CR 701.19a: "Regenerate this creature" is a shield on the source, for
  -- the rest of the turn and used up once.
  Spec.it s "reads regeneration as a shield on the source" $ do
    Spec.assertEq s (Right ()) (accepts drudgeSkeletons)
    Spec.assertEq s [Nothing] [matching | Effect.Replace r <- activatedEffects (translated drudgeSkeletons), Replace.duration r == Duration.UntilEndOfTurn, Replace.uses r == Uses.Once, ReplacementEffect.DestructionR (DestructionR.MkDestructionR matching DestructionRewrite.Regenerate) <- [Replace.effect r]]

  -- CR 701.19a / 608.2h: "Regenerate enchanted creature" shields the host the
  -- Aura has as the ability resolves, bound once by a loop, never re-read.
  Spec.it s "reads regeneration of the enchanted creature as a shield on the bound host" $ do
    Spec.assertEq s (Right ()) (accepts regeneration)
    let regenerated = SlotName.MkSlotName (Text.pack "regenerated")
    Spec.assertEq s [(ObjectRef.EachMatching Filter.IsHostOfSource, [Just (Filter.IsBound regenerated)])] [(ForEach.ref l, [matching | Effect.Replace r <- Foldable.toList (ForEach.body l), ReplacementEffect.DestructionR (DestructionR.MkDestructionR matching DestructionRewrite.Regenerate) <- [Replace.effect r]]) | Effect.ForEach l <- activatedEffects (translated regeneration), ForEach.slot l == regenerated]

  -- CR 614.1d: "This artifact enters tapped."
  Spec.it s "reads entering tapped as a replacement effect of the source" $ do
    Spec.assertEq s (Right ()) (accepts charcoalDiamond)
    Spec.assertEq s [ReplacementEffect.EntryR (EntryR.MkEntryR Filter.IsSource EntryRewrite.Tapped)] (fmap PrintedReplacement.effect (Face.replacementEffects (translated charcoalDiamond)))

  -- CR 601.2i / 112.2: the caster of a spell is its controller, which a
  -- cast trigger's filter names; "a player" names none.
  Spec.it s "reads a cast trigger's caster as the spell's controller" $ do
    Spec.assertEq s (Right ()) (accepts verduranEnchantress)
    Spec.assertEq s (Right ()) (accepts crystalRod)
    Spec.assertEq s [Filter.And [Filter.HasCardType CardType.Enchantment, Filter.HeldBy Holder.Controller PlayerRelation.You]] (castFilters verduranEnchantress)
    Spec.assertEq s [Filter.HasColor Color.Blue] (castFilters crystalRod)

  -- CR 602.1a / 701.21a: "Sacrifice a creature" as a cost.
  Spec.it s "reads sacrificing a permanent of a description as a cost" $ do
    Spec.assertEq s (Right ()) (accepts fallenAngel)
    Spec.assertEq s [[CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) (Filter.HasCardType CardType.Creature))]] (fmap (Cost.components . ActivatedAbility.cost) (Face.activatedAbilities (translated fallenAngel)))

  -- CR 106.1: "Add {W} or {U}" is one mode for each kind of mana, the rest
  -- of the instructions in each.
  Spec.it s "reads an or of mana as one mode per kind" $ do
    Spec.assertEq s (Right ()) (accepts adarkarWastes)
    Spec.assertEq s [1, 2] (fmap (length . Modal.modes . ActivatedAbility.modal) (Face.activatedAbilities (translated adarkarWastes)))

  -- CR 109.2: "target creature" is a creature target, not a permanent one
  -- of a description, as the pool writes it.
  Spec.it s "reads a creature target as a creature slot" $ do
    Spec.assertEq s [Pool.Creatures] (fmap TargetSlot.pool (spellSlots (translated giantGrowth)))

  -- CR 115.1 / 601.2c: "another target creature" of a spell is another than
  -- the first target, which mtgish names by its reference, not the source.
  Spec.it s "reads another target as other than the target it names" $ do
    Spec.assertEq s (Right ()) (accepts fallOfTheHammer)
    let filters = fmap TargetSlot.filter (Map.elems (spellSlotMap (translated fallOfTheHammer)))
    Spec.assertEq s [Just (Filter.HeldBy Holder.Controller PlayerRelation.You), Just (Filter.Not (Filter.IsBound (SlotName.MkSlotName (Text.pack "target1"))))] filters

  -- CR 301.5a: what an Equipment's static ability affects is the creature
  -- it is attached to.
  Spec.it s "reads the host of an Equipment as the creature it is attached to" $ do
    Spec.assertEq s (Right ()) (accepts bonesplitter)
    Spec.assertEq s [Affected.Matching (Filter.And [Filter.HasCardType CardType.Creature, Filter.HasAttached Filter.IsSource])] (fmap StaticAbility.affected (Face.staticAbilities (translated bonesplitter)))

  -- CR 604.3: Nightmare's two abilities define one star each, and Dakmor
  -- Sorceress's one is written into both boxes, as the pool writes it; the
  -- printed 4 in the other box is what the engine reads there.
  Spec.it s "writes a characteristic-defining ability into both boxes" $ do
    Spec.assertEq s (Right ()) (accepts nightmare)
    Spec.assertEq s (Right ()) (accepts dakmorSorceress)
    let defined = Face.characteristicPT (translated dakmorSorceress)
    Spec.assertNe s Nothing defined
    Spec.assertEq s (fmap CharacteristicPT.power defined) (fmap CharacteristicPT.toughness defined)

  -- CR 118.12: "you may pay {1}{U}. If you do, draw a card."
  Spec.it s "gates the instructions after an optional cost on its payment" $ do
    Spec.assertEq s (Right ()) (accepts merfolkSeer)
    let gates = [PayGate.branch g | t <- Face.triggeredAbilities (translated merfolkSeer), m <- Foldable.toList (Modal.modes (TriggeredAbility.modal t)), c <- Foldable.toList (Mode.clauses m), Just g <- [Clause.payGate c]]
    Spec.assertEq s [PayBranch.IfPaid] gates

  -- CR 601.2d: damage divided among one or two targets.
  Spec.it s "divides damage among the targets it is divided among" $ do
    Spec.assertEq s (Right ()) (accepts twinBolt)
    let slots = spellSlots (translated twinBolt)
    Spec.assertEq s [Just (Quantity.Literal 2)] (fmap TargetSlot.divided slots)
    Spec.assertEq s [SlotCount.Printed (TargetCount.MkTargetCount 1 (Just 2))] (fmap TargetSlot.count slots)

  -- CR 107.4e: a hybrid symbol, as Parun.Ingest reads MTGJSON's "{R/W}".
  Spec.it s "reads a hybrid mana symbol" $ do
    Spec.assertEq s (Right ()) (accepts borosRecruit)
    Spec.assertEq s (Just (ManaCost.MkManaCost [ManaSymbol.Hybrid (Hybrid.MkHybrid (ManaType.Colored Color.Red) (ManaType.Colored Color.White))])) (Face.manaCost (translated borosRecruit))

  -- CR 603.4: "if there are no Zombies on the battlefield".
  Spec.it s "reads an intervening if clause" $ do
    Spec.assertEq s (Right ()) (accepts sarcomancy)
    Spec.assertEq s [False, True] (fmap (Maybe.isJust . TriggeredAbility.intervening) (Face.triggeredAbilities (translated sarcomancy)))

  -- CR 603.2b / 102.1: "the upkeep of enchanted creature's controller", a
  -- named player's turn read off the source slot.
  Spec.it s "reads a step trigger on enchanted creature's controller's turn" $ do
    Spec.assertEq s (Right ()) (accepts soulBleed)
    Spec.assertEq s [TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Beginning BeginningStep.Upkeep) Nothing (TurnScope.PlayersTurn (PlayerRef.HolderOfBound Holder.Controller Hop.Host (SlotName.MkSlotName (Text.pack "self")))))] (fmap TriggeredAbility.condition (Face.triggeredAbilities (translated soulBleed)))

  -- CR 611.3a: "as long as" as the condition of the static abilities within.
  Spec.it s "reads a static ability that applies as long as a condition holds" $ do
    Spec.assertEq s (Right ()) (accepts kirdApe)
    Spec.assertEq s (Right ()) (accepts wuAdmiral)
    Spec.assertEq s (Right ()) (accepts castleRaptors)
    let battlefield f = Quantity.Count (Count.MkCount (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) f Aggregation.Members)
        atLeastOne f = Just (Condition.Compares (Compares.MkCompares (battlefield f) Comparison.AtLeast (Quantity.Literal 1)))
    Spec.assertEq s [atLeastOne (Filter.And [Filter.HasSubtype Subtype.Forest, Filter.HeldBy Holder.Controller PlayerRelation.You])] (fmap StaticAbility.condition (Face.staticAbilities (translated kirdApe)))
    Spec.assertEq s [atLeastOne (Filter.And [Filter.HasSubtype Subtype.Island, Filter.HeldBy Holder.Controller PlayerRelation.Opponent])] (fmap StaticAbility.condition (Face.staticAbilities (translated wuAdmiral)))
    Spec.assertEq s [atLeastOne (Filter.And [Filter.IsSource, Filter.Not Filter.IsTapped])] (fmap StaticAbility.condition (Face.staticAbilities (translated castleRaptors)))
    Spec.assertEq s (Right ()) (accepts gaelicat)
    Spec.assertEq s (Right ()) (accepts anuridBarkripper)
    let atLeast q k = Just (Condition.Compares (Compares.MkCompares q Comparison.AtLeast (Quantity.Literal k)))
    Spec.assertEq s [atLeast (battlefield (Filter.And [Filter.HasCardType CardType.Artifact, Filter.HeldBy Holder.Controller PlayerRelation.You])) 2] (fmap StaticAbility.condition (Face.staticAbilities (translated gaelicat)))
    Spec.assertEq s [atLeast (Quantity.Count (Count.MkCount (Scope.InZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You))) (Filter.And []) Aggregation.Members)) 7] (fmap StaticAbility.condition (Face.staticAbilities (translated anuridBarkripper)))
    Spec.assertEq s (Right ()) (accepts bloodBurglar)
    Spec.assertEq s [Just (Condition.Compares (Compares.MkCompares (Quantity.IsActivePlayer (PlayerRef.Relative PlayerRelation.You)) Comparison.Exactly (Quantity.Literal 1)))] (fmap StaticAbility.condition (Face.staticAbilities (translated bloodBurglar)))

  -- CR 701.22a: "Scry 2."
  Spec.it s "reads scrying" $ do
    Spec.assertEq s (Right ()) (accepts crystalBall)
    Spec.assertEq s [PlayerQuantity.MkPlayerQuantity (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 2)] [q | Effect.Scry q <- activatedEffects (translated crystalBall)]

  -- CR 509.1b: can't be blocked, by creatures of a description, or except
  -- by them.
  Spec.it s "reads a creature that can't be blocked" $ do
    Spec.assertEq s (Right ()) (accepts phantomWarrior)
    Spec.assertEq s (Right ()) (accepts bogRats)
    Spec.assertEq s (Right ()) (accepts invisibility)
    let blockers face = [CantBeBlockedBy.blockers b | CombatRestriction.CantBeBlockedBy b <- Face.combatRestrictions face]
    Spec.assertEq s [Filter.And []] (blockers (translated phantomWarrior))
    Spec.assertEq s [Filter.HasSubtype Subtype.Wall] (blockers (translated bogRats))
    Spec.assertEq s [Filter.Not (Filter.HasSubtype Subtype.Wall)] (blockers (translated invisibility))

  -- CR 509.1b / 506.7a: a creature that can't be blocked this turn, by an
  -- ability activated only during your turn, before attackers are declared.
  Spec.it s "reads a creature that can't be blocked this turn" $ do
    Spec.assertEq s (Right ()) (accepts zhugeJin)
    Spec.assertEq s [[ActivationRestriction.DuringTurn TurnScope.ControllersTurn, ActivationRestriction.BeforeStep (Phase.Combat CombatStep.DeclareAttackers)]] (fmap ActivatedAbility.restrictions (Face.activatedAbilities (translated zhugeJin)))
    let unblocked = GrantedAbility.Rules mempty {RuleAbilities.combatRestrictions = [CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy (Affected.Matching Filter.IsSource) (Filter.And []) Nothing Nothing)]}
    Spec.assertEq s [(Duration.UntilEndOfTurn, Modification.GainAbility unblocked)] [(ModifyTarget.duration m, ModifyTarget.modification m) | Effect.ModifyTarget m <- activatedEffects (translated zhugeJin)]

  -- Every keyword that stands alone, as the rule naming it, round-trips to
  -- its own printed name: the round trip over the whole of that table.
  Spec.it s "round-trips every keyword that stands alone" $ do
    let failures = [(name, result) | k <- Oracle.Keyword.standalone, name : _ <- [Oracle.Keyword.printed Text.empty k], let result = accept (keywordCard name, Text.unpack name), either (const True) (const False) result]
    Spec.assertEq s [] failures

-- | The AST translated, stamped with the Oracle text, and held to it.
accept :: (String, String) -> Either Text.Text Card.Card
accept (ast, text) = do
  value <- Common.parse (Text.pack ast)
  card <- Mtgish.card value
  Mtgish.accepted card {Card.faces = fmap (\f -> f {Face.oracleText = Just (Text.pack text)}) (Card.faces card)}

-- | Whether the AST translates and is held to its text.
accepts :: (String, String) -> Either Text.Text ()
accepts = Functor.void . accept

-- | The AST's one face, which the test has already accepted.
translated :: (String, String) -> Face.Face Card.Card
translated (ast, _) = case Common.parse (Text.pack ast) >>= Mtgish.card of
  Right card -> NonEmpty.head (Card.faces card)
  Left reason -> error (Text.unpack reason)

spellSlotMap :: Face.Face Card.Card -> Map.Map SlotName.SlotName TargetSlot.TargetSlot
spellSlotMap face = foldMap Mode.targetSlots (Modal.modes (Face.spell face))

spellSlots :: Face.Face Card.Card -> [TargetSlot.TargetSlot]
spellSlots = Map.elems . spellSlotMap

-- | Every instruction of the face's activated abilities.
activatedEffects :: Face.Face Card.Card -> [Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)]
activatedEffects face = [e | a <- Face.activatedAbilities face, m <- Foldable.toList (Modal.modes (ActivatedAbility.modal a)), c <- Foldable.toList (Mode.clauses m), e <- Foldable.toList (Clause.effects c)]

-- | Every instruction of the face's spell.
spellEffects :: Face.Face Card.Card -> [Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)]
spellEffects face = [e | m <- Foldable.toList (Modal.modes (Face.spell face)), c <- Foldable.toList (Mode.clauses m), e <- Foldable.toList (Clause.effects c)]

-- | The filters of the cast triggers of the AST's face, which the test has
-- already accepted.
castFilters :: (String, String) -> [Filter.Filter Keyword.Keyword]
castFilters card = [SpellCast.filter c | t <- Face.triggeredAbilities (translated card), TriggerCondition.SpellCast c <- [TriggeredAbility.condition t]]

-- | A vanilla creature's AST with one keyword rule, named as mtgish names
-- it: the printed name's words run together ("FirstStrike", "JumpStart").
keywordCard :: Text.Text -> String
keywordCard name =
  let tag = concatMap (\w -> filter Char.isAlpha (Text.unpack (Text.toUpper (Text.take 1 w) <> Text.drop 1 w))) (Text.split (\c -> elem c " -") name)
   in "{\"_OracleCard\":\"Card\",\"Name\":\"Kith\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[]},\"ManaCost\":[],\"Rules\":[{\"_Rule\":\"" <> tag <> "\"}],\"CardPT\":{\"Power\":1,\"Toughness\":1}}"

-- | Shock's AST, and its Oracle text.
shock :: (String, String)
shock =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Shock\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Instant\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostR\"}],\"Rules\":[{\"_Rule\":\"SpellActions\",\"args\":{\"_Actions\":\"Targeted\",\"args\":[[{\"_Target\":\"AnyTarget\"}],{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"SpellDealsDamage\",\"args\":[{\"_Spell\":\"ThisSpell\"},{\"_GameNumber\":\"Integer\",\"args\":2},{\"_DamageRecipient\":\"Ref_AnyTarget\"}]}]}]}}]}",
    "Shock deals 2 damage to any target."
  )

-- | Giant Growth's AST, and its Oracle text.
giantGrowth :: (String, String)
giantGrowth =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Giant Growth\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Instant\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostG\"}],\"Rules\":[{\"_Rule\":\"SpellActions\",\"args\":{\"_Actions\":\"Targeted\",\"args\":[[{\"_Target\":\"TargetPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}}],{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreatePermanentLayerEffectUntil\",\"args\":[{\"_Permanent\":\"Ref_TargetPermanent\"},[{\"_LayerEffect\":\"AdjustPT\",\"args\":[3,3]}],{\"_Expiration\":\"UntilEndOfTurn\"}]}]}]}}]}",
    "Target creature gets +3/+3 until end of turn."
  )

-- | Fall of the Hammer's AST, and its Oracle text.
fallOfTheHammer :: (String, String)
fallOfTheHammer =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Fall of the Hammer\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Instant\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostR\"}],\"Rules\":[{\"_Rule\":\"SpellActions\",\"args\":{\"_Actions\":\"Targeted\",\"args\":[[{\"_Target\":\"TargetPermanent\",\"args\":{\"_Permanents\":\"And\",\"args\":[{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"},{\"_Permanents\":\"ControlledByAPlayer\",\"args\":{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"You\"}}}]}},{\"_Target\":\"TargetPermanent\",\"args\":{\"_Permanents\":\"And\",\"args\":[{\"_Permanents\":\"Other\",\"args\":{\"_Permanent\":\"Ref_TargetPermanent1\"}},{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}]}}],{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"PermanentDealsDamage\",\"args\":[{\"_Permanent\":\"Ref_TargetPermanent1\"},{\"_GameNumber\":\"PowerOfPermanent\",\"args\":{\"_Permanent\":\"Ref_TargetPermanent1\"}},{\"_DamageRecipient\":\"Permanent\",\"args\":{\"_Permanent\":\"Ref_TargetPermanent2\"}}]}]}]}}]}",
    "Target creature you control deals damage equal to its power to another target creature."
  )

-- | Bonesplitter's AST, and its Oracle text.
bonesplitter :: (String, String)
bonesplitter =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Bonesplitter\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Artifact\"],\"Subtypes\":[\"Equipment\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1}],\"Rules\":[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"HostPermanent\"},[{\"_StaticLayerEffect\":\"AdjustPT\",\"args\":[2,0]}]]},{\"_Rule\":\"Equip\",\"args\":[{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"},{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1}]}]}]}",
    "Equipped creature gets +2/+0.\nEquip {1}"
  )

-- | Nightmare's AST, and its Oracle text.
nightmare :: (String, String)
nightmare =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Nightmare\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Nightmare\",\"Horse\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":5},{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"Flying\"},{\"_Rule\":\"CDA_Power\",\"args\":{\"_GameNumber\":\"TheNumberOfPermanentsOnTheBattlefield\",\"args\":{\"_Permanents\":\"And\",\"args\":[{\"_Permanents\":\"IsLandType\",\"args\":\"Swamp\"},{\"_Permanents\":\"ControlledByAPlayer\",\"args\":{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"You\"}}}]}}},{\"_Rule\":\"CDA_Toughness\",\"args\":{\"_GameNumber\":\"TheNumberOfPermanentsOnTheBattlefield\",\"args\":{\"_Permanents\":\"And\",\"args\":[{\"_Permanents\":\"IsLandType\",\"args\":\"Swamp\"},{\"_Permanents\":\"ControlledByAPlayer\",\"args\":{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"You\"}}}]}}}],\"CardPT\":{\"Power\":0,\"Toughness\":0}}",
    "Flying (This creature can't be blocked except by creatures with flying or reach.)\nNightmare's power and toughness are each equal to the number of Swamps you control."
  )

-- | Merfolk Seer's AST, and its Oracle text.
merfolkSeer :: (String, String)
merfolkSeer =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Merfolk Seer\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Merfolk\",\"Wizard\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2},{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"TriggerA\",\"args\":[{\"_Trigger\":\"WhenAPermanentDies\",\"args\":{\"_Permanents\":\"SinglePermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"MayCost\",\"args\":{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostU\"}]}},{\"_Action\":\"If\",\"args\":[{\"_Condition\":\"CostWasPaid\"},[{\"_Action\":\"DrawACard\"}]]}]}]}],\"CardPT\":{\"Power\":2,\"Toughness\":2}}",
    "When this creature dies, you may pay {1}{U}. If you do, draw a card."
  )

-- | Twin Bolt's AST, and its Oracle text.
twinBolt :: (String, String)
twinBolt =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Twin Bolt\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Instant\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostR\"}],\"Rules\":[{\"_Rule\":\"SpellActions\",\"args\":{\"_Actions\":\"TargetedDistributed\",\"args\":[[{\"_DistributedTarget\":\"BetweenOneAndNumberAnyTargets\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":2}}],{\"_Distribution\":\"DistributeNumberAmongTargets\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":2}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"SpellDealsDistributedDamage\",\"args\":{\"_Spell\":\"ThisSpell\"}}]}]}}]}",
    "Twin Bolt deals 2 damage divided as you choose among one or two targets."
  )

-- | Boros Recruit's AST, and its Oracle text.
borosRecruit :: (String, String)
borosRecruit =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Boros Recruit\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Goblin\",\"Soldier\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostRW\"}],\"Rules\":[{\"_Rule\":\"FirstStrike\"}],\"CardPT\":{\"Power\":1,\"Toughness\":1}}",
    "({R/W} can be paid with either {R} or {W}.)\nFirst strike"
  )

-- | Drudge Skeletons's AST, and its Oracle text.
drudgeSkeletons :: (String, String)
drudgeSkeletons =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Drudge Skeletons\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Skeleton\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostB\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"RegeneratePermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}}]}]}],\"CardPT\":{\"Power\":1,\"Toughness\":1}}",
    "{B}: Regenerate this creature. (The next time this creature would be destroyed this turn, instead tap it, remove it from combat, and heal all damage on it.)"
  )

-- | Regeneration's AST, and its Oracle text.
regeneration :: (String, String)
regeneration =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Regeneration\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[\"Aura\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostG\"}],\"Rules\":[{\"_Rule\":\"EnchantPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}},{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostG\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"RegeneratePermanent\",\"args\":{\"_Permanent\":\"HostPermanent\"}}]}]}]}",
    "Enchant creature (Target a creature as you cast this. This card enters attached to that creature.)\n{G}: Regenerate enchanted creature. (The next time that creature would be destroyed this turn, instead tap it, remove it from combat, and heal all damage on it.)"
  )

-- | Soul Bleed's AST, and its Oracle text.
soulBleed :: (String, String)
soulBleed =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Soul Bleed\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[\"Aura\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2},{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"EnchantPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}},{\"_Rule\":\"TriggerA\",\"args\":[{\"_Trigger\":\"AtTheBeginningOfAPlayersUpkeep\",\"args\":{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"HostController\"}}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"PlayerAction\",\"args\":[{\"_Player\":\"Trigger_ThatPlayer\"},{\"_Action\":\"LoseLife\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":1}}]}]}]}]}",
    "Enchant creature\nAt the beginning of the upkeep of enchanted creature's controller, that player loses 1 life."
  )

-- | Sarcomancy's AST, and its Oracle text.
sarcomancy :: (String, String)
sarcomancy =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Sarcomancy\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"TriggerA\",\"args\":[{\"_Trigger\":\"WhenAPermanentEntersTheBattlefield\",\"args\":{\"_Permanents\":\"SinglePermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreateTokens\",\"args\":[[{\"_CreatableToken\":\"TokenWithPT\",\"args\":[{\"_PT\":\"PT\",\"args\":[2,2]},{\"_TokenColorList\":\"Colors\",\"args\":[\"Black\"]},[],[\"Creature\"],{\"_TokenSubtypes\":\"SubtypesList\",\"args\":[\"Zombie\"]},[]]}],[]]}]}]},{\"_Rule\":\"TriggerI\",\"args\":[{\"_Trigger\":\"AtTheBeginningOfAPlayersUpkeep\",\"args\":{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"You\"}}},{\"_Condition\":\"NoPermanentsPassFilter\",\"args\":[{\"_Permanents\":\"IsCreatureType\",\"args\":\"Zombie\"},{\"_Permanents\":\"OnTheBattlefield\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"PermanentDealsDamage\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},{\"_GameNumber\":\"Integer\",\"args\":1},{\"_DamageRecipient\":\"Player\",\"args\":{\"_Player\":\"You\"}}]}]}]}]}",
    "When this enchantment enters, create a 2/2 black Zombie creature token.\nAt the beginning of your upkeep, if there are no Zombies on the battlefield, this enchantment deals 1 damage to you."
  )

-- | Dakmor Sorceress's AST, and its Oracle text.
dakmorSorceress :: (String, String)
dakmorSorceress =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Dakmor Sorceress\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Human\",\"Wizard\",\"Sorcerer\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":5},{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"CDA_Power\",\"args\":{\"_GameNumber\":\"TheNumberOfPermanentsOnTheBattlefield\",\"args\":{\"_Permanents\":\"And\",\"args\":[{\"_Permanents\":\"IsLandType\",\"args\":\"Swamp\"},{\"_Permanents\":\"ControlledByAPlayer\",\"args\":{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"You\"}}}]}}}],\"CardPT\":{\"Power\":0,\"Toughness\":4}}",
    "Dakmor Sorceress's power is equal to the number of Swamps you control."
  )

-- | Millstone's AST, and its Oracle text.
millstone :: (String, String)
millstone =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Millstone\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Artifact\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2}],\"Rules\":[{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"And\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2}]},{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}}]},{\"_Actions\":\"Targeted\",\"args\":[[{\"_Target\":\"TargetPlayer\",\"args\":{\"_Players\":\"AnyPlayer\"}}],{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"PlayerAction\",\"args\":[{\"_Player\":\"Ref_TargetPlayer\"},{\"_Action\":\"MillNumberCards\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":2}}]}]}]}]}]}",
    "{2}, {T}: Target player mills two cards."
  )

-- | Verduran Enchantress's AST, and its Oracle text.
verduranEnchantress :: (String, String)
verduranEnchantress =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Verduran Enchantress\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Human\",\"Druid\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostG\"},{\"_ManaSymbol\":\"ManaCostG\"}],\"Rules\":[{\"_Rule\":\"TriggerA\",\"args\":[{\"_Trigger\":\"WhenAPlayerCastsASpell\",\"args\":[{\"_Players\":\"SinglePlayer\",\"args\":{\"_Player\":\"You\"}},{\"_Spells\":\"IsCardtype\",\"args\":\"Enchantment\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"MayAction\",\"args\":{\"_Action\":\"DrawACard\"}}]}]}],\"CardPT\":{\"Power\":0,\"Toughness\":2}}",
    "Whenever you cast an enchantment spell, you may draw a card."
  )

-- | Crystal Rod's AST, and its Oracle text.
crystalRod :: (String, String)
crystalRod =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Crystal Rod\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Artifact\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1}],\"Rules\":[{\"_Rule\":\"TriggerA\",\"args\":[{\"_Trigger\":\"WhenAPlayerCastsASpell\",\"args\":[{\"_Players\":\"AnyPlayer\"},{\"_Spells\":\"IsColor\",\"args\":{\"_Color\":\"Blue\"}}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"MayCost\",\"args\":{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1}]}},{\"_Action\":\"If\",\"args\":[{\"_Condition\":\"CostWasPaid\"},[{\"_Action\":\"GainLife\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":1}}]]}]}]}]}",
    "Whenever a player casts a blue spell, you may pay {1}. If you do, you gain 1 life."
  )

-- | Fallen Angel's AST, and its Oracle text.
fallenAngel :: (String, String)
fallenAngel =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Fallen Angel\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Angel\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":3},{\"_ManaSymbol\":\"ManaCostB\"},{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"Flying\"},{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"SacrificeAPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreatePermanentLayerEffectUntil\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_LayerEffect\":\"AdjustPT\",\"args\":[2,1]}],{\"_Expiration\":\"UntilEndOfTurn\"}]}]}]}],\"CardPT\":{\"Power\":3,\"Toughness\":3}}",
    "Flying\nSacrifice a creature: This creature gets +2/+1 until end of turn."
  )

-- | Adarkar Wastes's AST, and its Oracle text.
adarkarWastes :: (String, String)
adarkarWastes =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Adarkar Wastes\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Land\"],\"Subtypes\":[]},\"Rules\":[{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"AddMana\",\"args\":{\"_ManaProduce\":\"ManaProduceC\"}}]}]},{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"AddMana\",\"args\":{\"_ManaProduce\":\"Or\",\"args\":[{\"_ManaProduce\":\"ManaProduceW\"},{\"_ManaProduce\":\"ManaProduceU\"}]}},{\"_Action\":\"PermanentDealsDamage\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},{\"_GameNumber\":\"Integer\",\"args\":1},{\"_DamageRecipient\":\"Player\",\"args\":{\"_Player\":\"You\"}}]}]}]}]}",
    "{T}: Add {C}.\n{T}: Add {W} or {U}. This land deals 1 damage to you."
  )

-- | Charcoal Diamond's AST, and its Oracle text.
charcoalDiamond :: (String, String)
charcoalDiamond =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Charcoal Diamond\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Artifact\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2}],\"Rules\":[{\"_Rule\":\"AsPermanentEnters\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_ReplacementActionWouldEnter\":\"EntersTapped\"}]]},{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"AddMana\",\"args\":{\"_ManaProduce\":\"ManaProduceB\"}}]}]}]}",
    "This artifact enters tapped.\n{T}: Add {B}."
  )

-- | Spitting Drake's AST, and its Oracle text.
vampireBats :: (String, String)
vampireBats =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Vampire Bats\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Bat\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"Flying\"},{\"_Rule\":\"ActivatedWithModifiers\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostB\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreatePermanentLayerEffectUntil\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_LayerEffect\":\"AdjustPT\",\"args\":[1,0]}],{\"_Expiration\":\"UntilEndOfTurn\"}]}]},{\"_ActivateModifier\":\"ActivateNoMoreThanNumberTimesEachTurn\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":2}}]}],\"CardPT\":{\"Power\":0,\"Toughness\":1}}",
    "Flying\n{B}: This creature gets +1/+0 until end of turn. Activate no more than twice each turn."
  )

spittingDrake :: (String, String)
spittingDrake =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Spitting Drake\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Drake\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":3},{\"_ManaSymbol\":\"ManaCostR\"}],\"Rules\":[{\"_Rule\":\"Flying\"},{\"_Rule\":\"ActivatedWithModifiers\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostR\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreatePermanentLayerEffectUntil\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_LayerEffect\":\"AdjustPT\",\"args\":[1,0]}],{\"_Expiration\":\"UntilEndOfTurn\"}]}]},{\"_ActivateModifier\":\"ActivateOnlyOnceEachTurn\"}]}],\"CardPT\":{\"Power\":2,\"Toughness\":2}}",
    "Flying\n{R}: This creature gets +1/+0 until end of turn. Activate only once each turn."
  )

-- | Disrupting Scepter's AST, and its Oracle text.
disruptingScepter :: (String, String)
disruptingScepter =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Disrupting Scepter\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Artifact\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":3}],\"Rules\":[{\"_Rule\":\"ActivatedWithModifiers\",\"args\":[{\"_Cost\":\"And\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":3}]},{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}}]},{\"_Actions\":\"Targeted\",\"args\":[[{\"_Target\":\"TargetPlayer\",\"args\":{\"_Players\":\"AnyPlayer\"}}],{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"PlayerAction\",\"args\":[{\"_Player\":\"Ref_TargetPlayer\"},{\"_Action\":\"DiscardACard\"}]}]}]},{\"_ActivateModifier\":\"ActivateOnlyIf\",\"args\":{\"_Condition\":\"PlayerPassesFilter\",\"args\":[{\"_Player\":\"You\"},{\"_Players\":\"IsTheirTurn\"}]}}]}]}",
    "{3}, {T}: Target player discards a card. Activate only during your turn."
  )

-- | Worldly Tutor's AST, and its Oracle text.
worldlyTutor :: (String, String)
worldlyTutor =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Worldly Tutor\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Instant\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostG\"}],\"Rules\":[{\"_Rule\":\"SpellActions\",\"args\":{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"SearchLibrary\",\"args\":[{\"_SearchLibraryAction\":\"FindACardOfType\",\"args\":{\"_CardsInLibrary\":\"IsCardtype\",\"args\":\"Creature\"}},{\"_SearchLibraryAction\":\"RevealFoundCards\"},{\"_SearchLibraryAction\":\"SetAsideFoundCards\"},{\"_SearchLibraryAction\":\"Shuffle\"},{\"_SearchLibraryAction\":\"PutSetAsideCardsOnTopOfLibrary\"}]}]}}]}",
    "Search your library for a creature card, reveal it, then shuffle and put the card on top."
  )

-- | Light of Day's AST, and its Oracle text.
lightOfDay :: (String, String)
lightOfDay =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Light of Day\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":3},{\"_ManaSymbol\":\"ManaCostW\"}],\"Rules\":[{\"_Rule\":\"EachPermanentRuleEffect\",\"args\":[{\"_Permanents\":\"And\",\"args\":[{\"_Permanents\":\"IsColor\",\"args\":{\"_Color\":\"Black\"}},{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}]},[{\"_PermanentRule\":\"CantAttack\"},{\"_PermanentRule\":\"CantBlock\"}]]}]}",
    "Black creatures can't attack or block."
  )

-- | Firebreathing's AST, and its Oracle text.
firebreathing :: (String, String)
firebreathing =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Firebreathing\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[\"Aura\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostR\"}],\"Rules\":[{\"_Rule\":\"EnchantPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}},{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostR\"}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreatePermanentLayerEffectUntil\",\"args\":[{\"_Permanent\":\"HostPermanent\"},[{\"_LayerEffect\":\"AdjustPT\",\"args\":[1,0]}],{\"_Expiration\":\"UntilEndOfTurn\"}]}]}]}]}",
    "Enchant creature\n{R}: Enchanted creature gets +1/+0 until end of turn."
  )

-- | Chill's AST, and its Oracle text.
chill :: (String, String)
chill =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Chill\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"EachPlayerEffect\",\"args\":[{\"_Players\":\"AnyPlayer\"},[{\"_PlayerEffect\":\"IncreaseSpellCost\",\"args\":[{\"_Spells\":\"IsColor\",\"args\":{\"_Color\":\"Red\"}},{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2}]}]}]]}]}",
    "Red spells cost {2} more to cast."
  )

-- | Index's AST, and its Oracle text.
index :: (String, String)
index =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Index\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Sorcery\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"SpellActions\",\"args\":{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"LookAtTheTopNumberCardsOfLibrary\",\"args\":[{\"_GameNumber\":\"Integer\",\"args\":5},[{\"_LookAtTopOfLibraryAction\":\"PutTheRemainingCardsOnTopOfLibraryInAnyOrder\"}]]}]}}]}",
    "Look at the top five cards of your library, then put them back in any order."
  )

-- | Kird Ape's AST, and its Oracle text.
kirdApe :: (String, String)
kirdApe =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Kird Ape\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Ape\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostR\"}],\"Rules\":[{\"_Rule\":\"If\",\"args\":[{\"_Condition\":\"PlayerPassesFilter\",\"args\":[{\"_Player\":\"You\"},{\"_Players\":\"ControlsA\",\"args\":{\"_Permanents\":\"IsLandType\",\"args\":\"Forest\"}}]},[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_StaticLayerEffect\":\"AdjustPT\",\"args\":[1,2]}]]}]]}],\"CardPT\":{\"Power\":1,\"Toughness\":1}}",
    "This creature gets +1/+2 as long as you control a Forest."
  )

-- | Wu Admiral's AST, and its Oracle text.
wuAdmiral :: (String, String)
wuAdmiral =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Wu Admiral\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Human\",\"Soldier\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":4},{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"If\",\"args\":[{\"_Condition\":\"APlayerPassesFilter\",\"args\":[{\"_Players\":\"Opponent\"},{\"_Players\":\"ControlsA\",\"args\":{\"_Permanents\":\"IsLandType\",\"args\":\"Island\"}}]},[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_StaticLayerEffect\":\"AdjustPT\",\"args\":[1,1]}]]}]]}],\"CardPT\":{\"Power\":3,\"Toughness\":3}}",
    "This creature gets +1/+1 as long as an opponent controls an Island."
  )

-- | Castle Raptors's AST, and its Oracle text.
castleRaptors :: (String, String)
castleRaptors =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Castle Raptors\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Bird\",\"Soldier\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":4},{\"_ManaSymbol\":\"ManaCostW\"}],\"Rules\":[{\"_Rule\":\"Flying\"},{\"_Rule\":\"If\",\"args\":[{\"_Condition\":\"PermanentPassesFilter\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},{\"_Permanents\":\"IsUntapped\"}]},[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_StaticLayerEffect\":\"AdjustPT\",\"args\":[0,2]}]]}]]}],\"CardPT\":{\"Power\":3,\"Toughness\":3}}",
    "Flying\nAs long as this creature is untapped, it gets +0/+2."
  )

-- | Crystal Ball's AST, and its Oracle text.
crystalBall :: (String, String)
crystalBall =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Crystal Ball\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Artifact\"],\"Subtypes\":[]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":3}],\"Rules\":[{\"_Rule\":\"Activated\",\"args\":[{\"_Cost\":\"And\",\"args\":[{\"_Cost\":\"PayMana\",\"args\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1}]},{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}}]},{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"Scry\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":2}}]}]}]}",
    "{1}, {T}: Scry 2. (Look at the top two cards of your library, then put any number of them on the bottom and the rest on top in any order.)"
  )

-- | Phantom Warrior's AST, and its Oracle text.
phantomWarrior :: (String, String)
phantomWarrior =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Phantom Warrior\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Illusion\",\"Warrior\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostU\"},{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"PermanentRuleEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_PermanentRule\":\"CantBeBlocked\"}]]}],\"CardPT\":{\"Power\":2,\"Toughness\":2}}",
    "This creature can't be blocked."
  )

-- | Bog Rats's AST, and its Oracle text.
bogRats :: (String, String)
bogRats =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Bog Rats\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Rat\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"PermanentRuleEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_PermanentRule\":\"CantBeBlockedByDefenders\",\"args\":{\"_Permanents\":\"IsCreatureType\",\"args\":\"Wall\"}}]]}],\"CardPT\":{\"Power\":1,\"Toughness\":1}}",
    "This creature can't be blocked by Walls."
  )

-- | Invisibility's AST, and its Oracle text.
invisibility :: (String, String)
invisibility =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Invisibility\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Enchantment\"],\"Subtypes\":[\"Aura\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostU\"},{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"EnchantPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}},{\"_Rule\":\"PermanentRuleEffect\",\"args\":[{\"_Permanent\":\"HostPermanent\"},[{\"_PermanentRule\":\"CantBeBlockedExceptByDefenders\",\"args\":{\"_Permanents\":\"IsCreatureType\",\"args\":\"Wall\"}}]]}]}",
    "Enchant creature\nEnchanted creature can't be blocked except by Walls."
  )

-- | Zhuge Jin, Wu Strategist's AST, and its Oracle text.
zhugeJin :: (String, String)
zhugeJin =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Zhuge Jin, Wu Strategist\",\"Typeline\":{\"Supertypes\":[\"Legendary\"],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Human\",\"Advisor\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostU\"},{\"_ManaSymbol\":\"ManaCostU\"}],\"Rules\":[{\"_Rule\":\"ActivatedWithModifiers\",\"args\":[{\"_Cost\":\"TapPermanent\",\"args\":{\"_Permanent\":\"ThisPermanent\"}},{\"_Actions\":\"Targeted\",\"args\":[[{\"_Target\":\"TargetPermanent\",\"args\":{\"_Permanents\":\"IsCardtype\",\"args\":\"Creature\"}}],{\"_Actions\":\"ActionList\",\"args\":[{\"_Action\":\"CreatePermanentRuleEffectUntil\",\"args\":[{\"_Permanent\":\"Ref_TargetPermanent\"},[{\"_PermanentRule\":\"CantBeBlocked\"}],{\"_Expiration\":\"UntilEndOfTurn\"}]}]}]},{\"_ActivateModifier\":\"ActivateOnlyIf\",\"args\":{\"_Condition\":\"And\",\"args\":[{\"_Condition\":\"PlayerPassesFilter\",\"args\":[{\"_Player\":\"You\"},{\"_Players\":\"IsTheirTurn\"}]},{\"_Condition\":\"IsBeforeAttackersDeclared\"}]}}]}],\"CardPT\":{\"Power\":1,\"Toughness\":1}}",
    "{T}: Target creature can't be blocked this turn. Activate only during your turn, before attackers are declared."
  )

-- | Gaelicat's AST, and its Oracle text.
gaelicat :: (String, String)
gaelicat =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Gaelicat\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Cat\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":2},{\"_ManaSymbol\":\"ManaCostW\"}],\"Rules\":[{\"_Rule\":\"Flying\"},{\"_Rule\":\"Vigilance\"},{\"_Rule\":\"If\",\"args\":[{\"_Condition\":\"PlayerPassesFilter\",\"args\":[{\"_Player\":\"You\"},{\"_Players\":\"ControlsNum\",\"args\":[{\"_Comparison\":\"GreaterThanOrEqualTo\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":2}},{\"_Permanents\":\"IsCardtype\",\"args\":\"Artifact\"}]}]},[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_StaticLayerEffect\":\"AdjustPT\",\"args\":[2,0]}]]}]]}],\"CardPT\":{\"Power\":1,\"Toughness\":3}}",
    "Flying, vigilance\nAs long as you control two or more artifacts, this creature gets +2/+0."
  )

-- | Anurid Barkripper's AST, and its Oracle text.
anuridBarkripper :: (String, String)
anuridBarkripper =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Anurid Barkripper\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Frog\",\"Beast\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostG\"},{\"_ManaSymbol\":\"ManaCostG\"}],\"Rules\":[{\"_Rule\":\"If\",\"args\":[{\"_Condition\":\"PlayerPassesFilter\",\"args\":[{\"_Player\":\"You\"},{\"_Players\":\"NumCardsInGraveyardIs\",\"args\":{\"_Comparison\":\"GreaterThanOrEqualTo\",\"args\":{\"_GameNumber\":\"Integer\",\"args\":7}}}]},[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_StaticLayerEffect\":\"AdjustPT\",\"args\":[2,2]}]]}]]}],\"CardPT\":{\"Power\":2,\"Toughness\":2}}",
    "Threshold \8212 This creature gets +2/+2 as long as there are seven or more cards in your graveyard."
  )

-- | Blood Burglar's AST, and its Oracle text.
bloodBurglar :: (String, String)
bloodBurglar =
  ( "{\"_OracleCard\":\"Card\",\"Name\":\"Blood Burglar\",\"Typeline\":{\"Supertypes\":[],\"Cardtypes\":[\"Creature\"],\"Subtypes\":[\"Vampire\",\"Rogue\"]},\"ManaCost\":[{\"_ManaSymbol\":\"ManaCostGeneric\",\"args\":1},{\"_ManaSymbol\":\"ManaCostB\"}],\"Rules\":[{\"_Rule\":\"If\",\"args\":[{\"_Condition\":\"IsPlayersTurn\",\"args\":{\"_Player\":\"You\"}},[{\"_Rule\":\"PermanentLayerEffect\",\"args\":[{\"_Permanent\":\"ThisPermanent\"},[{\"_StaticLayerEffect\":\"AddAbility\",\"args\":[{\"_Rule\":\"Lifelink\"}]}]]}]]}],\"CardPT\":{\"Power\":2,\"Toughness\":2}}",
    "During your turn, this creature has lifelink.(Damage dealt by this creature also causes you to gain that much life.)"
  )
