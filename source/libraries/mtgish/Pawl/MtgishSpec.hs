-- Covers Pawl.Mtgish and Pawl.Mtgish.Node on small committed mtgish ASTs,
-- each a line of mtgish's data/mtgish.lines.json (MIT) with its card's
-- Oracle text from MTGJSON.
module Pawl.MtgishSpec where

import qualified Data.Char as Char
import qualified Data.Foldable as Foldable
import qualified Data.Functor as Functor
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Maybe as Maybe
import qualified Data.Text as Text
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Mtgish as Mtgish
import qualified Pawl.Mtgish.Node as Node
import qualified Pawl.Oracle.Keyword as Oracle.Keyword
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.CharacteristicPT as CharacteristicPT
import qualified Pawl.Types.Clause as Clause
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.CostAmount as CostAmount
import qualified Pawl.Types.CostComponent as CostComponent
import qualified Pawl.Types.DestructionR as DestructionR
import qualified Pawl.Types.DestructionRewrite as DestructionRewrite
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.Effect as Effect
import qualified Pawl.Types.EntryR as EntryR
import qualified Pawl.Types.EntryRewrite as EntryRewrite
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.GrantedAbility as GrantedAbility
import qualified Pawl.Types.Hybrid as Hybrid
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.Modal as Modal
import qualified Pawl.Types.Mode as Mode
import qualified Pawl.Types.PayBranch as PayBranch
import qualified Pawl.Types.PayGate as PayGate
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.PrintedReplacement as PrintedReplacement
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.Replace as Replace
import qualified Pawl.Types.ReplacementEffect as ReplacementEffect
import qualified Pawl.Types.Sacrifice as Sacrifice
import qualified Pawl.Types.SlotCount as SlotCount
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.SpellCast as SpellCast
import qualified Pawl.Types.StaticAbility as StaticAbility
import qualified Pawl.Types.TargetCount as TargetCount
import qualified Pawl.Types.TargetSlot as TargetSlot
import qualified Pawl.Types.TriggerCondition as TriggerCondition
import qualified Pawl.Types.TriggeredAbility as TriggeredAbility
import qualified Pawl.Types.Uses as Uses

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Mtgish" $ do
  Spec.it s "reads a node's family, constructor and arguments" $ do
    Spec.assertEq s (Right (Node.MkNode "Action" "DrawACard" Nothing)) (Common.parse (Text.pack "{\"_Action\":\"DrawACard\"}") >>= Node.node)
    Spec.assertEq s (Left (Text.pack "_Action:DrawACard")) (Common.parse (Text.pack "{\"_Action\":\"DrawACard\"}") >>= Node.node >>= Node.untranslated :: Either Text.Text ())

  Spec.it s "accepts a translation that renders back to its Oracle text" $ do
    Spec.assertEq s (Right ()) (accepts shock)
    Spec.assertEq s (Right ()) (accepts giantGrowth)

  Spec.it s "rejects a translation whose rendering is not its Oracle text" $ do
    Spec.assertEq s (Left (Text.pack "renders as: Shock deals 2 damage to any target.")) (accepts (fst shock, "Shock deals 3 damage to any target."))

  -- A node not translated rejects the whole card, never only its ability:
  -- Millstone is nothing but the milling ability it stops at.
  Spec.it s "rejects a card at the first node it does not translate" $ do
    Spec.assertEq s (Left (Text.pack "_Action:MillNumberCards")) (accepts millstone)

  -- CR 701.19a: "Regenerate this creature" is a shield on the source, for
  -- the rest of the turn and used up once.
  Spec.it s "reads regeneration as a shield on the source" $ do
    Spec.assertEq s (Right ()) (accepts drudgeSkeletons)
    Spec.assertEq s [Nothing] [matching | Effect.Replace r <- activatedEffects (translated drudgeSkeletons), Replace.duration r == Duration.UntilEndOfTurn, Replace.uses r == Uses.Once, ReplacementEffect.DestructionR (DestructionR.MkDestructionR matching DestructionRewrite.Regenerate) <- [Replace.effect r]]

  -- CR 614.1d: "This artifact enters tapped."
  Spec.it s "reads entering tapped as a replacement effect of the source" $ do
    Spec.assertEq s (Right ()) (accepts charcoalDiamond)
    Spec.assertEq s [ReplacementEffect.EntryR (EntryR.MkEntryR Filter.IsSource EntryRewrite.Tapped)] (fmap PrintedReplacement.effect (Face.replacementEffects (translated charcoalDiamond)))

  -- CR 601.2i / 110.2: the caster of a spell is its controller, which a
  -- cast trigger's filter names; "a player" names none.
  Spec.it s "reads a cast trigger's caster as the spell's controller" $ do
    Spec.assertEq s (Right ()) (accepts verduranEnchantress)
    Spec.assertEq s (Right ()) (accepts crystalRod)
    Spec.assertEq s [Filter.And [Filter.HasCardType CardType.Enchantment, Filter.ControlledBy PlayerRelation.You]] (castFilters verduranEnchantress)
    Spec.assertEq s [Filter.HasColor Color.Blue] (castFilters crystalRod)

  -- CR 602.1a / 701.21a: "Sacrifice a creature" as a cost.
  Spec.it s "reads sacrificing a permanent of a description as a cost" $ do
    Spec.assertEq s (Right ()) (accepts fallenAngel)
    Spec.assertEq s [[CostComponent.Sacrifice (Sacrifice.MkSacrifice (CostAmount.Fixed 1) (Filter.HasCardType CardType.Creature))]] (fmap (Cost.components . ActivatedAbility.cost) (Face.activatedAbilities (translated fallenAngel)))

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
    Spec.assertEq s [Just (Filter.ControlledBy PlayerRelation.You), Just (Filter.Not (Filter.IsBound (SlotName.MkSlotName (Text.pack "target1"))))] filters

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

  -- CR 107.4e: a hybrid symbol, as Pawl.Ingest reads MTGJSON's "{R/W}".
  Spec.it s "reads a hybrid mana symbol" $ do
    Spec.assertEq s (Right ()) (accepts borosRecruit)
    Spec.assertEq s (Just (ManaCost.MkManaCost [ManaSymbol.Hybrid (Hybrid.MkHybrid (ManaType.Colored Color.Red) (ManaType.Colored Color.White))])) (Face.manaCost (translated borosRecruit))

  -- CR 603.4: "if there are no Zombies on the battlefield".
  Spec.it s "reads an intervening if clause" $ do
    Spec.assertEq s (Right ()) (accepts sarcomancy)
    Spec.assertEq s [False, True] (fmap (Maybe.isJust . TriggeredAbility.intervening) (Face.triggeredAbilities (translated sarcomancy)))

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
