-- Covers Pawl.Oracle and its modules on hand-built cards. Pawl.IngestSpec
-- checks it against the pool and the keyword codec.
module Pawl.OracleSpec where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Pawl.Oracle as Oracle
import qualified Pawl.Oracle.Normalise as Normalise
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Activator as Activator
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Clause as Clause
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.CostAmount as CostAmount
import qualified Pawl.Types.CostComponent as CostComponent
import qualified Pawl.Types.Counter as Counter
import qualified Pawl.Types.DamagePart as DamagePart
import qualified Pawl.Types.DealDamage as DealDamage
import qualified Pawl.Types.Destroy as Destroy
import qualified Pawl.Types.Draw as Draw
import qualified Pawl.Types.Effect as Effect
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.GrantedAbility as GrantedAbility
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Layout as Layout
import qualified Pawl.Types.LifeLoss as LifeLoss
import qualified Pawl.Types.LifeLossCause as LifeLossCause
import qualified Pawl.Types.ManaAddition as ManaAddition
import qualified Pawl.Types.ManaCost as ManaCost
import qualified Pawl.Types.ManaProduction as ManaProduction
import qualified Pawl.Types.ManaRetention as ManaRetention
import qualified Pawl.Types.ManaSymbol as ManaSymbol
import qualified Pawl.Types.ManaType as ManaType
import qualified Pawl.Types.Modal as Modal
import qualified Pawl.Types.Mode as Mode
import qualified Pawl.Types.ModeSelection as ModeSelection
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.Optionality as Optionality
import qualified Pawl.Types.PlayerQuantity as PlayerQuantity
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.Protection as Protection
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.Regenerability as Regenerability
import qualified Pawl.Types.SlotCount as SlotCount
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.Supertype as Supertype
import qualified Pawl.Types.TargetCount as TargetCount
import qualified Pawl.Types.TargetSlot as TargetSlot
import qualified Pawl.Types.TriggerCondition as TriggerCondition
import qualified Pawl.Types.TriggerLimit as TriggerLimit
import qualified Pawl.Types.TriggeredAbility as TriggeredAbility
import qualified Pawl.Types.TypeLine as TypeLine
import qualified Pawl.Types.Ward as Ward

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Oracle" $ do
  Spec.it s "normalise drops reminder text and splits a keyword line" $ do
    Spec.assertEq s (fmap Text.pack ["flying", "trample", "vigilance"]) (Normalise.normalise x (Text.pack "Flying, vigilance\nTrample (This creature can deal excess combat damage.)"))
    Spec.assertEq s [] (Normalise.normalise x (Text.pack "({T}: Add {G}.)"))
    Spec.assertEq s (fmap Text.pack ["haste", "horsemanship"]) (Normalise.normalise x (Text.pack "Haste; horsemanship (This creature can't be blocked except by creatures with horsemanship.)"))

  -- CR 201.4c / 201.5: a card names itself by its name, a legendary one by
  -- the part before the comma, and newer Oracle text as "this creature".
  Spec.it s "normalise writes every self-reference alike, and only whole words" $ do
    let rograkh = CardName.MkCardName (Text.pack "Rograkh, Son of Rohgahh")
        shock = CardName.MkCardName (Text.pack "Shock")
    Spec.assertEq s (Normalise.normalise rograkh (Text.pack "Rograkh, Son of Rohgahh deals 1 damage.")) (Normalise.normalise rograkh (Text.pack "Rograkh deals 1 damage."))
    Spec.assertEq s (Normalise.normalise rograkh (Text.pack "Rograkh deals 1 damage.")) (Normalise.normalise rograkh (Text.pack "This creature deals 1 damage."))
    Spec.assertEq s [Text.pack "~ deals 2 damage to any target."] (Normalise.normalise shock (Text.pack "Shock deals 2 damage to any target."))
    Spec.assertEq s [Text.pack "shockwave."] (Normalise.normalise shock (Text.pack "Shockwave."))

  Spec.it s "render prints one keyword per line, and nothing for a vanilla face" $ do
    Spec.assertEq s (Just (Text.pack "Flying\nVigilance")) (Oracle.render (card Layout.Normal [[Keyword.Flying, Keyword.Vigilance]]))
    Spec.assertEq s (Just Text.empty) (Oracle.render (card Layout.Normal [[]]))

  Spec.it s "render answers only for a single normal face" $ do
    Spec.assertEq s Nothing (Oracle.render (card Layout.Normal [[Keyword.Flying], [Keyword.Flying]]))
    Spec.assertEq s Nothing (Oracle.render (card Layout.Split [[Keyword.Flying]]))

  -- CR 702: a keyword's number or cost follows it, a cost of more than mana
  -- after a dash; a quality reads as a colour's name or a plural.
  Spec.it s "render prints a keyword with its payload" $ do
    Spec.assertEq s (Just (Text.pack "Rampage 2")) (Oracle.render (card Layout.Normal [[Keyword.Rampage 2]]))
    Spec.assertEq s (Just (Text.pack "Echo {1}{G}")) (Oracle.render (card Layout.Normal [[Keyword.Echo (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1, green])) [])]]))
    Spec.assertEq s (Just (Text.pack "Ward\8212Pay 3 life.")) (Oracle.render (card Layout.Normal [[Keyword.Ward (Ward.MkWard (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.PayLife (CostAmount.Fixed 3)]) Nothing)]]))
    Spec.assertEq s (Just (Text.pack "Protection from red")) (Oracle.render (card Layout.Normal [[Keyword.Protection (Protection.MkProtection (Filter.HasColor Color.Red) Nothing)]]))
    Spec.assertEq s (Just (Text.pack "Affinity for artifacts")) (Oracle.render (card Layout.Normal [[Keyword.Affinity (Filter.HasCardType CardType.Artifact)]]))
    Spec.assertEq s (Just (Text.pack "Nonbasic landwalk")) (Oracle.render (card Layout.Normal [[Keyword.Landwalk (Filter.Not (Filter.HasSupertype Supertype.Basic))]]))

  -- CR 602.1a: "[Cost]: [Effect.]"; CR 107.5's {T}; CR 106.1's mana.
  Spec.it s "render prints an activated mana ability" $ do
    let ability = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis]) (addMana 1)
        twice = activated (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) [CostComponent.TapThis, CostComponent.SacrificeThis]) (addMana 2)
    Spec.assertEq s (Just (Text.pack "{T}: Add {G}.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [ability]})))
    Spec.assertEq s (Just (Text.pack "{1}, {T}, Sacrifice Spark: Add {G}{G}.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [twice]})))

  -- CR 120.1 / 115.4: the source deals the damage, to "any target".
  Spec.it s "render prints a damage spell" $ do
    let bolt = spell [clause [damage [(target, 3)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s (Just (Text.pack "Spark deals 3 damage to any target.")) (Oracle.render bolt)
    let char = spell [clause [damage [(target, 4), (you, 2)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s (Just (Text.pack "Spark deals 4 damage to any target and 2 damage to you.")) (Oracle.render char)

  -- CR 601.2d: damage divided among a slot's targets.
  Spec.it s "render prints damage divided among targets" $ do
    let slot = (TargetSlot.required Pool.AnyTarget Nothing) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 1 (Just 3)), TargetSlot.divided = Just (Quantity.Literal 3)}
        arc = spell [clause [Effect.DealDamage (DealDamage.MkDealDamage (Seq.singleton (DamagePart.MkDamagePart (ObjectRef.InSlot target) (Quantity.Share target))) Nothing Nothing)]] [(target, slot)]
    Spec.assertEq s (Just (Text.pack "Spark deals 3 damage divided as you choose among one, two, or three targets.")) (Oracle.render arc)

  -- CR 701.8 / 701.19c: "destroy", and "can't be regenerated" after it; the
  -- type adjective before the colour one, as Terror prints them.
  Spec.it s "render prints a destroy spell and its filter" $ do
    let terror = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.CantBeRegenerated]] [(target, TargetSlot.required Pool.Creatures (Just (Filter.And [Filter.Not (Filter.HasColor Color.Black), Filter.Not (Filter.HasCardType CardType.Artifact)])))]
    Spec.assertEq s (Just (Text.pack "Destroy target nonartifact, nonblack creature. It can't be regenerated.")) (Oracle.render terror)
    let wrath = spell [clause [destroy (ObjectRef.EachMatching (Filter.HasCardType CardType.Creature)) Regenerability.CantBeRegenerated]] []
    Spec.assertEq s (Just (Text.pack "Destroy all creatures. They can't be regenerated.")) (Oracle.render wrath)
    let salt = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Permanents (Just (Filter.HasCardType CardType.Land))) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s (Just (Text.pack "Destroy two target lands.")) (Oracle.render salt)

  -- Oracle drifted from "You draw" to an imperative "Draw"; both render.
  Spec.it s "render answers both wordings of drawing" $ do
    let divination = spell [clause [draw (PlayerRef.Relative PlayerRelation.You) 2]] []
    Spec.assertEq s [Text.pack "Draw two cards.", Text.pack "You draw two cards."] (Oracle.renderings divination)

  -- A second instruction for the same player drops the subject; for another
  -- player it is joined by "and", starts a sentence or starts a paragraph, as
  -- printings differ.
  Spec.it s "render strings a clause's instructions together" $ do
    let sign = spell [clause [draw (PlayerRef.InSlot target) 2, loseLife (PlayerRef.InSlot target) 2]] [(target, TargetSlot.required Pool.Players Nothing)]
    Spec.assertEq s [Text.pack "Target player draws two cards and loses 2 life."] (Oracle.renderings sign)
    let feast = spell [clause [damage [(target, 4)], gainLife 4]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s [Text.pack "Spark deals 4 damage to any target and you gain 4 life.", Text.pack "Spark deals 4 damage to any target. You gain 4 life.", Text.pack "Spark deals 4 damage to any target.\nYou gain 4 life."] (Oracle.renderings feast)

  -- CR 601.2c: each target slot is announced once, so text naming a slot
  -- twice, or never, is not the mode's.
  Spec.it s "render answers nothing for a mode naming a slot other than once" $ do
    let twice = spell [clause [damage [(target, 1)]], clause [damage [(target, 1)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
        never = spell [clause [gainLife 1]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s Nothing (Oracle.render twice)
    Spec.assertEq s Nothing (Oracle.render never)

  -- Oracle text writes consecutive mana in one "Add" (Sol Ring), repeats an
  -- amount or shares it (Brothers of Fire, Earthquake), and deals damage to
  -- "each of" several targets (Jagged Lightning).
  Spec.it s "render joins mana and damage as Oracle text does" $ do
    let ring = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis]) (addMana 1)
        sol = ring {ActivatedAbility.modal = payload [clause [addMana 1, addMana 1]] []}
    Spec.assertEq s (Just (Text.pack "{T}: Add {G}{G}.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [sol]})))
    let brothers = spell [clause [damage [(target, 1), (you, 1)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s [Text.pack "Spark deals 1 damage to any target and you.", Text.pack "Spark deals 1 damage to any target and 1 damage to you."] (Oracle.renderings brothers)
    let jagged = spell [clause [damage [(target, 3)]]] [(target, (TargetSlot.required Pool.Creatures Nothing) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s (Just (Text.pack "Spark deals 3 damage to each of two target creatures.")) (Oracle.render jagged)

  -- CR 701.6a: "counter"; CR 603.5: "you may".
  Spec.it s "render prints a counterspell and an optional instruction" $ do
    let cancel = spell [clause [Effect.Counter (Counter.MkCounter (ObjectRef.InSlot target) Nothing Nothing Nothing)]] [(target, TargetSlot.required Pool.Spells (Just (Filter.Not (Filter.HasCardType CardType.Creature))))]
    Spec.assertEq s (Just (Text.pack "Counter target noncreature spell.")) (Oracle.render cancel)
    let maybeDraw = spell [(clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.optionality = Optionality.Optional (PlayerRef.Relative PlayerRelation.You)}] []
    Spec.assertEq s (Just (Text.pack "You may draw a card.")) (Oracle.render maybeDraw)

  -- CR 603.6a / 700.4: "When [this] enters" and "When [this] dies", the
  -- effect naming the source again as "it".
  Spec.it s "render prints a trigger on entering or dying" $ do
    let imp = triggered TriggerCondition.SelfEnters [clause [damage [(target, 2)]]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s [Text.pack "When Spark enters, Spark deals 2 damage to target creature.", Text.pack "When Spark enters, it deals 2 damage to target creature."] (Oracle.renderings (withFace (\f -> f {Face.triggeredAbilities = [imp]})))
    let star = triggered TriggerCondition.SelfDies [clause [draw (PlayerRef.Relative PlayerRelation.You) 1]] []
    Spec.assertEq s (Just (Text.pack "When Spark dies, draw a card.")) (Oracle.render (withFace (\f -> f {Face.triggeredAbilities = [star]})))

  -- Protections may share a line (Paladin en-Vec); a disjunction of colours
  -- reads "and/or" in the plural (Ignite Disorder), of card types "and"
  -- (Devastation).
  Spec.it s "render shares a line of protections and pluralises a disjunction" $ do
    let from c = Keyword.Protection (Protection.MkProtection (Filter.HasColor c) Nothing)
    Spec.assertEq s [Text.pack "Protection from black\nProtection from red", Text.pack "Protection from black and from red"] (Oracle.renderings (card Layout.Normal [[from Color.Black, from Color.Red]]))
    let devastation = spell [clause [destroy (ObjectRef.EachMatching (Filter.Or [Filter.HasCardType CardType.Creature, Filter.HasCardType CardType.Land])) Regenerability.Regenerable]] []
    Spec.assertEq s (Just (Text.pack "Destroy all creatures and lands.")) (Oracle.render devastation)
    let colours = Filter.Or [Filter.HasColor Color.White, Filter.HasColor Color.Blue]
        ignite = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Creatures (Just colours)) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s [Text.pack "Destroy two target white or blue creatures.", Text.pack "Destroy two target white and/or blue creatures."] (Oracle.renderings ignite)

-- The name the normalisation cases give their card.
x :: CardName.CardName
x = CardName.MkCardName (Text.pack "X")

-- The slot most cases target through, and the one the engine binds "you" to.
target :: SlotName.SlotName
target = SlotName.MkSlotName (Text.pack "target")

you :: SlotName.SlotName
you = SlotName.MkSlotName (Text.pack "you")

green :: ManaSymbol.ManaSymbol
green = ManaSymbol.OfType (ManaType.Colored Color.Green)

-- Instructions, as the cards above print them.
addMana :: Integer -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
addMana n = Effect.AddMana (ManaAddition.MkManaAddition (PlayerRef.Relative PlayerRelation.You) (ManaProduction.OfType (ManaType.Colored Color.Green)) (Quantity.Literal n) ManaRetention.Ordinary Nothing Nothing Nothing)

damage :: [(SlotName.SlotName, Integer)] -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
damage parts = Effect.DealDamage (DealDamage.MkDealDamage (Seq.fromList (fmap (\(slot, n) -> DamagePart.MkDamagePart (ObjectRef.InSlot slot) (Quantity.Literal n)) parts)) Nothing Nothing)

destroy :: ObjectRef.ObjectRef -> Regenerability.Regenerability -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
destroy ref regenerability = Effect.Destroy (Destroy.MkDestroy ref regenerability Nothing Nothing Nothing)

draw :: PlayerRef.PlayerRef -> Integer -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
draw who n = Effect.Draw (Draw.MkDraw who (Quantity.Literal n) Nothing)

loseLife :: PlayerRef.PlayerRef -> Integer -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
loseLife who n = Effect.LoseLife (LifeLoss.MkLifeLoss who (Quantity.Literal n) LifeLossCause.ByEffect Nothing)

gainLife :: Integer -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
gainLife n = Effect.GainLife (PlayerQuantity.MkPlayerQuantity (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal n))

-- A triggered ability on this event, of one mode.
triggered :: TriggerCondition.TriggerCondition -> [Clause.Clause Card.Card (GrantedAbility.GrantedAbility Card.Card)] -> [(SlotName.SlotName, TargetSlot.TargetSlot)] -> TriggeredAbility.TriggeredAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)
triggered event clauses slots = TriggeredAbility.MkTriggeredAbility event (payload clauses slots) Nothing Nothing TriggerLimit.Unlimited Set.empty

-- A clause that always happens, of these instructions.
clause :: [Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)] -> Clause.Clause Card.Card (GrantedAbility.GrantedAbility Card.Card)
clause effects = Clause.MkClause Nothing Nothing Nothing Optionality.Mandatory Nothing (Seq.fromList effects)

-- A payload of one mode, of these clauses and target slots.
payload :: [Clause.Clause Card.Card (GrantedAbility.GrantedAbility Card.Card)] -> [(SlotName.SlotName, TargetSlot.TargetSlot)] -> Modal.Modal Card.Card (GrantedAbility.GrantedAbility Card.Card)
payload clauses slots = Modal.MkModal (Seq.singleton (Mode.MkMode (Seq.fromList clauses) (Map.fromList slots))) (ModeSelection.ChooseExactly 1)

-- An instant named Spark whose spell is this payload.
spell :: [Clause.Clause Card.Card (GrantedAbility.GrantedAbility Card.Card)] -> [(SlotName.SlotName, TargetSlot.TargetSlot)] -> Card.Card
spell clauses slots = withFace (\f -> f {Face.spell = payload clauses slots, Face.typeLine = TypeLine.MkTypeLine Set.empty (Set.singleton CardType.Instant) Set.empty})

-- An activated ability of this cost and the one instruction.
activated :: Cost.Cost Keyword.Keyword -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card) -> ActivatedAbility.ActivatedAbility Card.Card (GrantedAbility.GrantedAbility Card.Card)
activated cost e = ActivatedAbility.MkActivatedAbility cost [] 0 Nothing (payload [clause [e]] []) [] Activator.Controller Nothing Nothing Nothing

-- A normal card of one face named Spark, changed as given.
withFace :: (Face.Face Card.Card -> Face.Face Card.Card) -> Card.Card
withFace change = Card.MkCard Layout.Normal (NonEmpty.singleton (change (blank [])))

-- A card of the given layout whose faces carry the given keywords and nothing
-- else.
card :: Layout.Layout -> [[Keyword.Keyword]] -> Card.Card
card layout keywords =
  Card.MkCard
    { Card.layout = layout,
      Card.faces = NonEmpty.fromList (fmap blank keywords)
    }

-- A face named Spark of no type, carrying these keywords and nothing else.
blank :: [Keyword.Keyword] -> Face.Face Card.Card
blank ks = Oracle.bare (CardName.MkCardName (Text.pack "Spark")) Nothing Nothing Set.empty (TypeLine.MkTypeLine Set.empty Set.empty Set.empty) Nothing Nothing (Map.fromList (fmap (\k -> (k, 1)) ks))
