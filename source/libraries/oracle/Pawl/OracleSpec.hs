-- Covers Pawl.Oracle and its modules on hand-built cards. Pawl.IngestSpec
-- checks it against the pool and the keyword codec.
module Pawl.OracleSpec where

import qualified Control.Monad as Monad
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Pawl.Oracle as Oracle
import qualified Pawl.Oracle.Face as Oracle.Face
import qualified Pawl.Oracle.Normalise as Normalise
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ActivatedAbility as ActivatedAbility
import qualified Pawl.Types.Activator as Activator
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.Card as Card
import qualified Pawl.Types.CardName as CardName
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.ChosenPermanents as ChosenPermanents
import qualified Pawl.Types.Clause as Clause
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Cost as Cost
import qualified Pawl.Types.CostAmount as CostAmount
import qualified Pawl.Types.CostComponent as CostComponent
import qualified Pawl.Types.CountedDiscard as CountedDiscard
import qualified Pawl.Types.Counter as Counter
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Create as Create
import qualified Pawl.Types.DamageKind as DamageKind
import qualified Pawl.Types.DamagePart as DamagePart
import qualified Pawl.Types.DealDamage as DealDamage
import qualified Pawl.Types.Destroy as Destroy
import qualified Pawl.Types.Discard as Discard
import qualified Pawl.Types.Draw as Draw
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.Effect as Effect
import qualified Pawl.Types.EntryRiders as EntryRiders
import qualified Pawl.Types.Face as Face
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.GrantedAbility as GrantedAbility
import qualified Pawl.Types.HowMany as HowMany
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.Layout as Layout
import qualified Pawl.Types.LibraryPlacement as LibraryPlacement
import qualified Pawl.Types.LibraryPosition as LibraryPosition
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
import qualified Pawl.Types.Modification as Modification
import qualified Pawl.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Pawl.Types.ModifyTarget as ModifyTarget
import qualified Pawl.Types.MoveToZone as MoveToZone
import qualified Pawl.Types.ObjectRef as ObjectRef
import qualified Pawl.Types.Optionality as Optionality
import qualified Pawl.Types.PlayerQuantity as PlayerQuantity
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.PlayerScope as PlayerScope
import qualified Pawl.Types.Pool as Pool
import qualified Pawl.Types.Power as Power
import qualified Pawl.Types.PreventNextDamage as PreventNextDamage
import qualified Pawl.Types.Protection as Protection
import qualified Pawl.Types.PutCounters as PutCounters
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.RandomCardInHand as RandomCardInHand
import qualified Pawl.Types.Regenerability as Regenerability
import qualified Pawl.Types.SlotCount as SlotCount
import qualified Pawl.Types.SlotName as SlotName
import qualified Pawl.Types.StaticAbility as StaticAbility
import qualified Pawl.Types.Subtype as Subtype
import qualified Pawl.Types.Supertype as Supertype
import qualified Pawl.Types.TapState as TapState
import qualified Pawl.Types.TargetCount as TargetCount
import qualified Pawl.Types.TargetSlot as TargetSlot
import qualified Pawl.Types.TheseDiscard as TheseDiscard
import qualified Pawl.Types.Together as Together
import qualified Pawl.Types.Toughness as Toughness
import qualified Pawl.Types.TriggerCondition as TriggerCondition
import qualified Pawl.Types.TriggerLimit as TriggerLimit
import qualified Pawl.Types.TriggeredAbility as TriggeredAbility
import qualified Pawl.Types.TypeLine as TypeLine
import qualified Pawl.Types.Ward as Ward
import qualified Pawl.Types.Zone as Zone
import qualified Pawl.Types.ZoneScope as ZoneScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Oracle" $ do
  Spec.it s "normalise drops reminder text and splits a keyword line" $ do
    Spec.assertEq s (fmap Text.pack ["flying", "trample", "vigilance"]) (Normalise.normalise x (Text.pack "Flying, vigilance\nTrample (This creature can deal excess combat damage.)"))
    Spec.assertEq s [] (Normalise.normalise x (Text.pack "({T}: Add {G}.)"))
    Spec.assertEq s (fmap Text.pack ["haste", "horsemanship"]) (Normalise.normalise x (Text.pack "Haste; horsemanship (This creature can't be blocked except by creatures with horsemanship.)"))

  -- CR 201.5 / 201.5c: a card names itself by its name, a legendary one by
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

  -- CR 701.8 / 608.2c: "destroy", and "can't be regenerated" after it; the
  -- type adjective before the colour one, as Terror prints them.
  Spec.it s "render prints a destroy spell and its filter" $ do
    let terror = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.CantBeRegenerated]] [(target, TargetSlot.required Pool.Creatures (Just (Filter.And [Filter.Not (Filter.HasColor Color.Black), Filter.Not (Filter.HasCardType CardType.Artifact)])))]
    Spec.assertEq s (Just (Text.pack "Destroy target nonartifact, nonblack creature. It can't be regenerated.")) (Oracle.render terror)
    let wrath = spell [clause [destroy (ObjectRef.EachMatching (Filter.HasCardType CardType.Creature)) Regenerability.CantBeRegenerated]] []
    Spec.assertEq s (Just (Text.pack "Destroy all creatures. They can't be regenerated.")) (Oracle.render wrath)
    let salt = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Permanents (Just (Filter.HasCardType CardType.Land))) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s (Just (Text.pack "Destroy two target lands.")) (Oracle.render salt)

  -- "You" is left out of a sentence of its own and kept before "and", where
  -- current Oracle text repeats it (Ancient Craving) and older text does not
  -- (Ambition's Cost), and a second instruction may follow ", then" (Owl
  -- Familiar); beside another player's instruction it stands alone (Afterlife
  -- Insurance) or keeps "you" before "and" (Bad Deal).
  Spec.it s "render leaves out a lone you and keeps one before and" $ do
    let divination = spell [clause [draw (PlayerRef.Relative PlayerRelation.You) 2]] []
    Spec.assertEq s [Text.pack "Draw two cards."] (Oracle.renderings divination)
    let craving = spell [clause [draw (PlayerRef.Relative PlayerRelation.You) 3, loseLife (PlayerRef.Relative PlayerRelation.You) 3]] []
    Spec.assertEq s (Just (Text.pack "You draw three cards and you lose 3 life.")) (Oracle.render craving)
    Spec.assertEq s [Text.pack "You draw three cards and you lose 3 life.", Text.pack "You draw three cards and lose 3 life.", Text.pack "Draw three cards, then lose 3 life."] (Oracle.renderings craving)
    let insurance = spell [clause [loseLife (PlayerRef.InSlot target) 2, draw (PlayerRef.Relative PlayerRelation.You) 1]] [(target, TargetSlot.required Pool.Players Nothing)]
    Spec.assertEq s [Text.pack "Target player loses 2 life. Draw a card.", Text.pack "Target player loses 2 life.\nDraw a card.", Text.pack "Target player loses 2 life. Then draw a card.", Text.pack "Target player loses 2 life and you draw a card."] (Oracle.renderings insurance)

  -- A second instruction for the same player drops the subject; for another
  -- player it is joined by "and" (Vampiric Feast), starts a sentence (Soul
  -- Shred), one opened by "Then" (Return of the Nightstalkers), or starts a
  -- paragraph (Bargain), as printings differ, "and" first.
  Spec.it s "render strings a clause's instructions together" $ do
    let sign = spell [clause [draw (PlayerRef.InSlot target) 2, loseLife (PlayerRef.InSlot target) 2]] [(target, TargetSlot.required Pool.Players Nothing)]
    Spec.assertEq s [Text.pack "Target player draws two cards and loses 2 life.", Text.pack "Target player draws two cards, then loses 2 life."] (Oracle.renderings sign)
    let feast = spell [clause [damage [(target, 4)], gainLife 4]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s (Just (Text.pack "Spark deals 4 damage to any target and you gain 4 life.")) (Oracle.render feast)
    Spec.assertEq s [Text.pack "Spark deals 4 damage to any target and you gain 4 life.", Text.pack "Spark deals 4 damage to any target. You gain 4 life.", Text.pack "Spark deals 4 damage to any target.\nYou gain 4 life.", Text.pack "Spark deals 4 damage to any target. Then you gain 4 life."] (Oracle.renderings feast)

  -- CR 601.2c: each target slot is announced once, so text naming a slot
  -- twice, or never, is not the mode's.
  Spec.it s "render answers nothing for a mode naming a slot other than once" $ do
    let twice = spell [clause [damage [(target, 1)]], clause [damage [(target, 1)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
        never = spell [clause [gainLife 1]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s Nothing (Oracle.render twice)
    Spec.assertEq s Nothing (Oracle.render never)

  -- Oracle text writes consecutive mana in one "Add" (Sol Ring) and ends the
  -- sentence there (Ancient Tomb), repeats an amount for a target (Brothers of
  -- Fire) and shares it among groups (Earthquake), and deals damage to "each
  -- of" several targets (Jagged Lightning).
  Spec.it s "render joins mana and damage as Oracle text does" $ do
    let ring = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis]) (addMana 1)
        sol = ring {ActivatedAbility.modal = payload [clause [addMana 1, addMana 1]] []}
    Spec.assertEq s (Just (Text.pack "{T}: Add {G}{G}.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [sol]})))
    let brothers = spell [clause [damage [(target, 1), (you, 1)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s [Text.pack "Spark deals 1 damage to any target and 1 damage to you."] (Oracle.renderings brothers)
    let tomb = ring {ActivatedAbility.modal = payload [clause [addMana 1, damage [(you, 2)]]] []}
    Spec.assertEq s [Text.pack "{T}: Add {G}. Spark deals 2 damage to you.", Text.pack "{T}: Add {G}. Then Spark deals 2 damage to you."] (Oracle.renderings (withFace (\f -> f {Face.activatedAbilities = [tomb]})))
    let earthquake = spell [clause [Effect.DealDamage (DealDamage.MkDealDamage (Seq.fromList [DamagePart.MkDamagePart (ObjectRef.EachMatching (Filter.HasCardType CardType.Creature)) (Quantity.Literal 2), DamagePart.MkDamagePart ObjectRef.EachPlayer (Quantity.Literal 2)]) Nothing Nothing)]] []
    Spec.assertEq s [Text.pack "Spark deals 2 damage to each creature and each player."] (Oracle.renderings earthquake)
    let jagged = spell [clause [damage [(target, 3)]]] [(target, (TargetSlot.required Pool.Creatures Nothing) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s (Just (Text.pack "Spark deals 3 damage to each of two target creatures.")) (Oracle.render jagged)

  -- CR 701.6a: "counter"; CR 603.5: "you may".
  Spec.it s "render prints a counterspell and an optional instruction" $ do
    let cancel = spell [clause [Effect.Counter (Counter.MkCounter (ObjectRef.InSlot target) Nothing Nothing Nothing)]] [(target, TargetSlot.required Pool.Spells (Just (Filter.Not (Filter.HasCardType CardType.Creature))))]
    Spec.assertEq s (Just (Text.pack "Counter target noncreature spell.")) (Oracle.render cancel)
    let maybeDraw = spell [(clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.optionality = Optionality.Optional (PlayerRef.Relative PlayerRelation.You)}] []
    Spec.assertEq s (Just (Text.pack "You may draw a card.")) (Oracle.render maybeDraw)

  -- CR 603.6a / 700.4: "When [this] enters" and "When [this] dies", the
  -- effect naming the source again as "it"; a noncreature "is put into a
  -- graveyard from the battlefield" (Chromatic Star).
  Spec.it s "render prints a trigger on entering or dying" $ do
    let imp = triggered TriggerCondition.SelfEnters [clause [damage [(target, 2)]]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s [Text.pack "When Spark enters, it deals 2 damage to target creature."] (Oracle.renderings (withFace (\f -> f {Face.triggeredAbilities = [imp]})))
    let star = triggered TriggerCondition.SelfDies [clause [draw (PlayerRef.Relative PlayerRelation.You) 1]] []
    Spec.assertEq s [Text.pack "When Spark dies, draw a card."] (Oracle.renderings (withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [star]})))
    Spec.assertEq s [Text.pack "When Spark is put into a graveyard from the battlefield, draw a card."] (Oracle.renderings (withFace (\f -> (typed [CardType.Artifact] [] f) {Face.triggeredAbilities = [star]})))

  -- An activated ability whose cost sacrifices its source calls it "it"
  -- (Mogg Mob).
  Spec.it s "render calls a sacrificed source it" $ do
    let mob = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.SacrificeThis]) (damage [(you, 3)])
    Spec.assertEq s [Text.pack "Sacrifice Spark: It deals 3 damage to you."] (Oracle.renderings (withFace (\f -> f {Face.activatedAbilities = [mob]})))

  -- CR 113.2c: a paragraph break starts another ability, so only a spell's
  -- instructions (one spell ability, CR 113.3a) may be broken across lines.
  Spec.it s "render keeps a triggered ability's sentences in one paragraph" $ do
    let slots = [(target, TargetSlot.required Pool.Creatures Nothing)]
        apart = triggered TriggerCondition.SelfEnters [clause [damage [(target, 2)]], clause [gainLife 2]] slots
        together = triggered TriggerCondition.SelfEnters [clause [damage [(target, 2)], gainLife 2]] slots
    Monad.forM_ [apart, together] $ \t -> do
      let rendered = Oracle.renderings (withFace (\f -> f {Face.triggeredAbilities = [t]}))
      Spec.assertBool s (not (null rendered)) "no rendering"
      Spec.assertEq s [] (filter (Text.isInfixOf (Text.pack "\n")) rendered)

  -- Protections share a line (Paladin en-Vec); a disjunction of colours reads
  -- "and/or" in the plural (Ignite Disorder), of other adjectives "or" (Fire at
  -- Will), of card types "and" (Devastation).
  Spec.it s "render shares a line of protections and pluralises a disjunction" $ do
    let from c = Keyword.Protection (Protection.MkProtection (Filter.HasColor c) Nothing)
    Spec.assertEq s [Text.pack "Protection from black and from red"] (Oracle.renderings (card Layout.Normal [[from Color.Black, from Color.Red]]))
    let devastation = spell [clause [destroy (ObjectRef.EachMatching (Filter.Or [Filter.HasCardType CardType.Creature, Filter.HasCardType CardType.Land])) Regenerability.Regenerable]] []
    Spec.assertEq s (Just (Text.pack "Destroy all creatures and lands.")) (Oracle.render devastation)
    let colours = Filter.Or [Filter.HasColor Color.White, Filter.HasColor Color.Blue]
        ignite = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Creatures (Just colours)) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s [Text.pack "Destroy two target white and/or blue creatures."] (Oracle.renderings ignite)
    let combatants = Filter.Or [Filter.IsAttacking, Filter.IsBlocking]
        fire = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Creatures (Just combatants)) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s [Text.pack "Destroy two target attacking or blocking creatures."] (Oracle.renderings fire)

  -- CR 611.2a: a change to an object "until end of turn", the duration ending
  -- the sentence (Giant Growth) or opening it (Aspirant's Ascent), ending it
  -- first; with no duration stated it lasts indefinitely (Riding the Dilu
  -- Horse).
  Spec.it s "render prints a change to power and toughness and its duration" $ do
    let growth = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 3 3)]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s (Just (Text.pack "Target creature gets +3/+3 until end of turn.")) (Oracle.render growth)
    Spec.assertEq s [Text.pack "Target creature gets +3/+3 until end of turn.", Text.pack "Until end of turn, target creature gets +3/+3."] (Oracle.renderings growth)
    let horse = spell [clause [modify (ObjectRef.InSlot target) Duration.Indefinite (pt 2 2), modify (ObjectRef.InSlot target) Duration.Indefinite (Modification.GainKeyword Keyword.Horsemanship)]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s [Text.pack "Target creature gets +2/+2 and gains horsemanship."] (Oracle.renderings horse)

  -- A zero takes the other change's sign (Saltfield Recluse); several targets
  -- "each get" a change (Hearts on Fire) but "gain" a keyword (Wind Sail);
  -- keywords gained join, and lost ones too (Xathrid Slyblade).
  Spec.it s "render signs a change and joins the keywords an effect grants" $ do
    let slot = (TargetSlot.required Pool.Creatures Nothing) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 1 (Just 2))}
        recluse = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt (-2) 0)]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s (Just (Text.pack "Target creature gets -2/-0 until end of turn.")) (Oracle.render recluse)
    let hearts = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 2 1)]] [(target, slot)]
    Spec.assertEq s (Just (Text.pack "One or two target creatures each get +2/+1 until end of turn.")) (Oracle.render hearts)
    let sail = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (Modification.GainKeyword Keyword.Flying)]] [(target, slot)]
    Spec.assertEq s (Just (Text.pack "One or two target creatures gain flying until end of turn.")) (Oracle.render sail)
    let self = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))
        changes = [Modification.LoseKeyword Keyword.Shroud, Modification.GainKeyword Keyword.FirstStrike, Modification.GainKeyword Keyword.Deathtouch]
        blade = spell [clause (fmap (modify self Duration.UntilEndOfTurn) changes)] []
    Spec.assertEq s (Just (Text.pack "Spark loses shroud and gains first strike and deathtouch until end of turn.")) (Oracle.render blade)

  -- CR 604.1: a static ability's objects "get" a change and "have" a
  -- keyword; "all" only before a bare noun (Night of Souls' Betrayal), never
  -- before a described one (Glorious Anthem, Bad Moon).
  Spec.it s "render prints an anthem" $ do
    let mine = Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You]
    Spec.assertEq s (Just (Text.pack "Creatures you control get +1/+1.")) (Oracle.render (withFace (\f -> f {Face.staticAbilities = [static (Affected.Matching mine) [pt 1 1]]})))
    Spec.assertEq s (Just (Text.pack "All creatures get -1/-1.")) (Oracle.render (withFace (\f -> f {Face.staticAbilities = [static (Affected.Matching (Filter.HasCardType CardType.Creature)) [pt (-1) (-1)]]})))
    let black = Filter.And [Filter.HasColor Color.Black, Filter.HasCardType CardType.Creature]
    Spec.assertEq s (Just (Text.pack "Black creatures get +1/+1.")) (Oracle.render (withFace (\f -> f {Face.staticAbilities = [static (Affected.Matching black) [pt 1 1]]})))
    let others = Filter.And [Filter.HasSubtype Subtype.Merfolk, Filter.Not Filter.IsSource]
    Spec.assertEq s (Just (Text.pack "Other Merfolk get +1/+1 and have islandwalk.")) (Oracle.render (withFace (\f -> f {Face.staticAbilities = [static (Affected.Matching others) [pt 1 1, Modification.GainKeyword (Keyword.Landwalk (Filter.HasSubtype Subtype.Island))]]})))

  -- CR 702.5a / 303.4b / 301.5a: an Aura's enchant ability and its "enchanted
  -- creature", an Equipment's "equipped creature"; one enchanting a card in a
  -- graveyard is not rendered yet.
  Spec.it s "render prints an Aura and an Equipment" $ do
    let attached = Affected.Matching (Filter.And [Filter.HasCardType CardType.Creature, Filter.HasAttached Filter.IsSource])
        boost = static attached [pt 2 2, Modification.GainKeyword Keyword.Trample]
        aura = withFace (\f -> (typed [CardType.Enchantment] [Subtype.Aura] f) {Face.enchant = [TargetSlot.required Pool.Creatures Nothing], Face.staticAbilities = [boost]})
    Spec.assertEq s (Just (Text.pack "Enchant creature\nEnchanted creature gets +2/+2 and has trample.")) (Oracle.render aura)
    let equipment = withFace (\f -> (typed [CardType.Artifact] [Subtype.Equipment] f) {Face.staticAbilities = [static attached [pt 2 0]]})
    Spec.assertEq s (Just (Text.pack "Equipped creature gets +2/+0.")) (Oracle.render equipment)
    let unattached = withFace (\f -> (typed [CardType.Creature] [] f) {Face.staticAbilities = [static attached [pt 2 0]]})
    Spec.assertEq s Nothing (Oracle.render unattached)
    let animate = withFace (\f -> (typed [CardType.Enchantment] [Subtype.Aura] f) {Face.enchant = [graveyard PlayerRelation.AnyPlayer (Just (Filter.HasCardType CardType.Creature))]})
    Spec.assertEq s Nothing (Oracle.render animate)

  -- CR 400.7 / 400.3: a card returns to its owner's hand, or from your
  -- graveyard to your hand or the battlefield; it is put on top of or into a
  -- library by place, and exiled (CR 701.13a).
  Spec.it s "render prints a zone change by where it goes" $ do
    let creature = [(target, TargetSlot.required Pool.Creatures Nothing)]
        mine = [(target, graveyard PlayerRelation.You (Just (Filter.HasCardType CardType.Creature)))]
        to zone slots = Oracle.renderings (spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) zone)]] slots)
    Spec.assertEq s [Text.pack "Return target creature to its owner's hand."] (to Zone.Hand creature)
    Spec.assertEq s [Text.pack "Return target creature card from your graveyard to your hand."] (to Zone.Hand mine)
    Spec.assertEq s [Text.pack "Exile target creature."] (to Zone.Exile creature)
    Spec.assertEq s [Text.pack "Put target creature on the bottom of its owner's library."] (to Zone.Library creature)
    Spec.assertEq s [Text.pack "Return target creature card from your graveyard to the battlefield."] (to Zone.Battlefield mine)
    Spec.assertEq s [] (to Zone.Battlefield creature)
    let tapped = (move (ObjectRef.InSlot target) Zone.Battlefield) {MoveToZone.riders = EntryRiders.defaultValue {EntryRiders.tapped = TapState.Tapped}}
    Spec.assertEq s [Text.pack "Return target creature card from your graveyard to the battlefield tapped."] (Oracle.renderings (spell [clause [Effect.MoveToZone tapped]] mine))
    let placed placement = Oracle.renderings (spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) Zone.Library) {MoveToZone.placement = placement}]] creature)
    Spec.assertEq s [Text.pack "Put target creature on top of its owner's library."] (placed (LibraryPlacement.Stated LibraryPosition.Top))
    Spec.assertEq s [Text.pack "Put target creature into its owner's library second from the top."] (placed (LibraryPlacement.Beneath (Quantity.Literal 1)))
    let theirs = [(target, (graveyard PlayerRelation.Opponent Nothing) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2)), TargetSlot.together = Just Together.InOneZone})]
    Spec.assertEq s [Text.pack "Return two target cards from an opponent's graveyard to their hand."] (to Zone.Hand theirs)
    let single = [(target, (graveyard PlayerRelation.AnyPlayer Nothing) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 0 (Just 3)), TargetSlot.together = Just Together.InOneZone})]
    Spec.assertEq s [Text.pack "Exile up to three target cards from a single graveyard."] (to Zone.Exile single)
    let anywhere = [(target, graveyard PlayerRelation.AnyPlayer Nothing)]
    Spec.assertEq s [Text.pack "Exile target card from a graveyard."] (to Zone.Exile anywhere)

  -- Several objects go to "their owners' hands" (Evacuation) or "their
  -- owner's hand" (Retract), and a description of them reads "all" or, in the
  -- singular, "each" (Denizen of the Deep), as printings differ.
  Spec.it s "render returns several objects to their owners' hands" $ do
    let evacuation = spell [clause [Effect.MoveToZone (move (ObjectRef.EachMatching (Filter.HasCardType CardType.Creature)) Zone.Hand)]] []
    Spec.assertEq s (Just (Text.pack "Return all creatures to their owners' hands.")) (Oracle.render evacuation)
    Spec.assertEq s [Text.pack "Return all creatures to their owners' hands.", Text.pack "Return all creatures to their owner's hand.", Text.pack "Return each creature to its owner's hand."] (Oracle.renderings evacuation)

  -- CR 400.7 / 603.10a: what a dying creature became is "it" after the event
  -- (Undying Beast); a card returns from your graveyard by name (Reassembling
  -- Skeleton).
  Spec.it s "render calls the card a dying creature became it" $ do
    let beast = triggered TriggerCondition.SelfDies [clause [Effect.MoveToZone (move (ObjectRef.InSlot became) Zone.Hand)]] []
    Spec.assertEq s (Just (Text.pack "When Spark dies, return it to its owner's hand.")) (Oracle.render (withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [beast]})))
    let rising = activated (Cost.MkCost (Just (ManaCost.MkManaCost [green])) []) (Effect.MoveToZone (move (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))) Zone.Battlefield) {MoveToZone.origin = Just Zone.Graveyard})
    Spec.assertEq s (Just (Text.pack "{G}: Return Spark from your graveyard to the battlefield.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [rising]})))

  -- CR 110.4a: every permanent type is "permanent", every one but land
  -- "nonland permanent" (Restoration Seminar).
  Spec.it s "render names a permanent card" $ do
    let permanents = [CardType.Artifact, CardType.Battle, CardType.Creature, CardType.Enchantment, CardType.Planeswalker]
        seminar = spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) Zone.Battlefield)]] [(target, graveyard PlayerRelation.You (Just (Filter.Or (fmap Filter.HasCardType permanents))))]
    Spec.assertEq s (Just (Text.pack "Return target nonland permanent card from your graveyard to the battlefield.")) (Oracle.render seminar)

  -- A nonlegendary object reads so (Cytoshape) or as one "that isn't
  -- legendary" (Urza's Ruinous Blast), as printings differ.
  Spec.it s "render prints a negated supertype both ways" $ do
    let blast = spell [clause [Effect.MoveToZone (move (ObjectRef.EachMatching (Filter.And [Filter.HasCardType CardType.Creature, Filter.Not (Filter.HasSupertype Supertype.Legendary)])) Zone.Exile)]] []
    Spec.assertEq s (Just (Text.pack "Exile all nonlegendary creatures.")) (Oracle.render blast)
    Spec.assertBool s (Oracle.says blast (CardName.MkCardName (Text.pack "Spark")) (Text.pack "Exile all creatures that aren't legendary.")) "no \"that aren't legendary\""

  -- CR 701.7a / 111.4: a token by its size, colours, subtypes in its name's
  -- order, card types and keywords; one named otherwise is not spelled out.
  Spec.it s "render prints a token by its characteristics" $ do
    Spec.assertEq s (Just (Text.pack "Create two 1/1 red Goblin creature tokens.")) (Oracle.render (spell [clause [create 2 (token "Goblin Token" [Color.Red] [Subtype.Goblin] 1 [])]] []))
    Spec.assertEq s (Just (Text.pack "Create a 1/1 blue Faerie Dragon creature token with flying.")) (Oracle.render (spell [clause [create 1 (token "Faerie Dragon Token" [Color.Blue] [Subtype.Dragon, Subtype.Faerie] 1 [Keyword.Flying])]] []))
    Spec.assertEq s (Just (Text.pack "Create an 8/8 colorless Elf Warrior creature token.")) (Oracle.render (spell [clause [create 1 (token "Elf Warrior Token" [] [Subtype.Elf, Subtype.Warrior] 8 [])]] []))
    Spec.assertEq s (Just (Text.pack "Create a 1/1 green and white Elf Warrior creature token.")) (Oracle.render (spell [clause [create 1 (token "Elf Warrior Token" [Color.Green, Color.White] [Subtype.Elf, Subtype.Warrior] 1 [])]] []))
    Spec.assertEq s Nothing (Oracle.render (spell [clause [create 1 (token "Rabid Sheep" [Color.Green] [Subtype.Sheep] 2 [])]] []))

  -- CR 122.1: counters by kind and number, on "each" of several objects.
  Spec.it s "render puts counters on objects" $ do
    let creature = [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s (Just (Text.pack "Put a +1/+1 counter on target creature.")) (Oracle.render (spell [clause [counters CounterKind.PlusOnePlusOne 1 (ObjectRef.InSlot target)]] creature))
    Spec.assertEq s (Just (Text.pack "Put two -1/-1 counters on each creature.")) (Oracle.render (spell [clause [counters CounterKind.MinusOneMinusOne 2 (ObjectRef.EachMatching (Filter.HasCardType CardType.Creature))]] []))
    Spec.assertEq s (Just (Text.pack "Put an indestructible counter on target creature.")) (Oracle.render (spell [clause [counters (CounterKind.Keyword Keyword.Indestructible) 1 (ObjectRef.InSlot target)]] creature))

  -- CR 701.41a: support names the instruction it means, on a spell for up to
  -- N target creatures (Lead by Example) and on a permanent for up to N other
  -- ones (Joraga Auxiliary); a spell may print the instruction instead (Travel
  -- Preparations), so it renders first.
  Spec.it s "render prints support as the instruction or its name" $ do
    let instruction = counters CounterKind.PlusOnePlusOne 1 (ObjectRef.InSlot target)
    Spec.assertEq s [Text.pack "Put a +1/+1 counter on each of up to two target creatures.", Text.pack "Support 2."] (Oracle.renderings (spell [clause [instruction]] [(target, upTo 2 Nothing)]))
    let ability slot = withFace (\f -> f {Face.activatedAbilities = [(activated (Cost.MkCost (Just (ManaCost.MkManaCost [green])) []) instruction) {ActivatedAbility.modal = payload [clause [instruction]] [(target, slot)]}]})
    Spec.assertEq s [Text.pack "{G}: Put a +1/+1 counter on each of up to two other target creatures.", Text.pack "{G}: Support 2."] (Oracle.renderings (ability (upTo 2 (Just (Filter.Not Filter.IsSource)))))
    Spec.assertEq s [Text.pack "{G}: Put a +1/+1 counter on each of up to two target creatures."] (Oracle.renderings (ability (upTo 2 Nothing)))

  -- CR 701.26a: tapping and untapping; "another target" for one other object.
  Spec.it s "render taps and untaps" $ do
    Spec.assertEq s (Just (Text.pack "Tap another target creature.")) (Oracle.render (spell [clause [Effect.Tap (ObjectRef.InSlot target)]] [(target, TargetSlot.required Pool.Creatures (Just (Filter.Not Filter.IsSource)))]))
    Spec.assertEq s (Just (Text.pack "Untap all creatures you control.")) (Oracle.render (spell [clause [Effect.Untap (ObjectRef.EachMatching (Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You]))]] []))
    let lands = ObjectRef.ChosenPermanents (ChosenPermanents.MkChosenPermanents (Filter.HasCardType CardType.Land) (PlayerRef.Relative PlayerRelation.You) (HowMany.UpTo (Just (Quantity.Literal 4))))
    Spec.assertEq s (Just (Text.pack "Untap up to four lands.")) (Oracle.render (spell [clause [Effect.Untap lands]] []))

  -- CR 701.9: a player discards cards of their choice or at random; "you"
  -- discards in the imperative.
  Spec.it s "render prints a discard" $ do
    let player = [(target, TargetSlot.required Pool.Players Nothing)]
    Spec.assertEq s (Just (Text.pack "Target player discards two cards.")) (Oracle.render (spell [clause [discard (PlayerRef.InSlot target) 2]] player))
    Spec.assertEq s (Just (Text.pack "Discard a card.")) (Oracle.render (spell [clause [discard (PlayerRef.Relative PlayerRelation.You) 1]] []))
    let random = Effect.Discard (Discard.These (TheseDiscard.MkTheseDiscard (ObjectRef.RandomCardInHand (RandomCardInHand.MkRandomCardInHand (PlayerRef.InSlot target) (Filter.And []) (Quantity.Literal 2))) Nothing))
    Spec.assertEq s (Just (Text.pack "Target player discards two cards at random.")) (Oracle.render (spell [clause [random]] player))
    let loot = spell [clause [draw (PlayerRef.Relative PlayerRelation.You) 1, discard (PlayerRef.Relative PlayerRelation.You) 1]] []
    Spec.assertBool s (elem (Text.pack "Draw a card, then discard a card.") (Oracle.renderings loot)) "no \", then\""

  -- CR 615.7: a shield preventing the next damage this turn.
  Spec.it s "render prints a prevention shield" $ do
    let shield kind ref = Effect.PreventNextDamage (PreventNextDamage.MkPreventNextDamage Duration.UntilEndOfTurn kind (Just ref) Nothing Nothing Nothing (Quantity.Literal 3) Seq.empty)
    Spec.assertEq s (Just (Text.pack "Prevent the next 3 damage that would be dealt to any target this turn.")) (Oracle.render (spell [clause [shield Nothing (ObjectRef.InSlot target)]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]))
    Spec.assertEq s (Just (Text.pack "Prevent the next 3 combat damage that would be dealt to you this turn.")) (Oracle.render (spell [clause [shield (Just DamageKind.Combat) (ObjectRef.InSlot you)]] []))

-- A move of these objects to this zone, with nothing else said.
move :: ObjectRef.ObjectRef -> Zone.Zone -> MoveToZone.MoveToZone (GrantedAbility.GrantedAbility Card.Card)
move ref zone = MoveToZone.MkMoveToZone ref zone EntryRiders.defaultValue Nothing Nothing LibraryPlacement.defaultValue Nothing

-- A target slot of cards in your graveyard, or a player's, matching the filter.
graveyard :: PlayerRelation.PlayerRelation -> Maybe (Filter.Filter Keyword.Keyword) -> TargetSlot.TargetSlot
graveyard whose = TargetSlot.required (Pool.CardsInGraveyard (ZoneScope.Scoped (PlayerScope.Related whose)))

-- A creature token of this name, colours, subtypes, size and keywords.
token :: String -> [Color.Color] -> [Subtype.Subtype] -> Integer -> [Keyword.Keyword] -> Card.Card
token name colours subtypes size keywords =
  let face = Oracle.Face.bare (CardName.MkCardName (Text.pack name)) Nothing Nothing (Set.fromList colours) (TypeLine.MkTypeLine Set.empty (Set.singleton CardType.Creature) (Set.fromList subtypes)) (Just (Power.MkPower (Quantity.Literal size))) (Just (Toughness.MkToughness (Quantity.Literal size))) (Map.fromList (fmap (\k -> (k, 1)) keywords))
   in Card.MkCard Layout.Normal (NonEmpty.singleton face)

-- An instruction creating this many of the token.
create :: Integer -> Card.Card -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
create n t = Effect.Create (Create.MkCreate (Quantity.Literal n) t EntryRiders.defaultValue Nothing (PlayerRef.Relative PlayerRelation.You))

-- An instruction putting this many counters of the kind on these objects.
counters :: CounterKind.CounterKind Keyword.Keyword -> Integer -> ObjectRef.ObjectRef -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
counters kind n ref = Effect.PutCounters (PutCounters.MkPutCounters kind (Quantity.Literal n) ref)

-- An instruction to the player to discard this many cards of their choice.
discard :: PlayerRef.PlayerRef -> Integer -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
discard who n = Effect.Discard (Discard.Counted (CountedDiscard.MkCountedDiscard who (Quantity.Literal n) Nothing))

-- A slot of up to this many creatures, matching the filter.
upTo :: Natural.Natural -> Maybe (Filter.Filter Keyword.Keyword) -> TargetSlot.TargetSlot
upTo n = TargetSlot.upTo n Pool.Creatures

-- The slot the engine binds the card a dying object became to.
became :: SlotName.SlotName
became = SlotName.MkSlotName (Text.pack "became")

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

-- A change to an object for a while.
modify :: ObjectRef.ObjectRef -> Duration.Duration -> Modification.Modification (GrantedAbility.GrantedAbility Card.Card) -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
modify ref duration change = Effect.ModifyTarget (ModifyTarget.MkModifyTarget duration change ref Nothing)

-- A change to power and toughness.
pt :: Integer -> Integer -> Modification.Modification (GrantedAbility.GrantedAbility Card.Card)
pt p t = Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness (Quantity.Literal p) (Quantity.Literal t))

-- A static ability that always applies these changes to these objects.
static :: Affected.Affected -> [Modification.Modification (GrantedAbility.GrantedAbility Card.Card)] -> StaticAbility.StaticAbility (GrantedAbility.GrantedAbility Card.Card)
static objects changes = StaticAbility.MkStaticAbility {StaticAbility.affected = objects, StaticAbility.condition = Nothing, StaticAbility.functionsFrom = Set.empty, StaticAbility.lingers = Nothing, StaticAbility.name = Nothing, StaticAbility.modifications = NonEmpty.fromList changes}

-- The face with these card types and subtypes.
typed :: [CardType.CardType] -> [Subtype.Subtype] -> Face.Face Card.Card -> Face.Face Card.Card
typed types subtypes f = f {Face.typeLine = TypeLine.MkTypeLine Set.empty (Set.fromList types) (Set.fromList subtypes)}

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
blank ks = Oracle.Face.bare (CardName.MkCardName (Text.pack "Spark")) Nothing Nothing Set.empty (TypeLine.MkTypeLine Set.empty Set.empty Set.empty) Nothing Nothing (Map.fromList (fmap (\k -> (k, 1)) ks))
