-- Covers Parun.Oracle and its modules on hand-built cards. Parun.IngestSpec
-- checks it against the pool and the keyword codec.
module Parun.OracleSpec where

import qualified Control.Monad as Monad
import qualified Data.List.NonEmpty as NonEmpty
import qualified Data.Map.Strict as Map
import qualified Data.Sequence as Seq
import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Numeric.Natural as Natural
import qualified Parun.Oracle as Oracle
import qualified Parun.Oracle.Face as Oracle.Face
import qualified Parun.Oracle.Normalise as Normalise
import qualified Parun.Spec as Spec
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
import qualified Parun.Types.CantBeBlockedBy as CantBeBlockedBy
import qualified Parun.Types.Card as Card
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CharacteristicPT as CharacteristicPT
import qualified Parun.Types.ChooseBetween as ChooseBetween
import qualified Parun.Types.ChosenPermanents as ChosenPermanents
import qualified Parun.Types.Clause as Clause
import qualified Parun.Types.ClauseIndex as ClauseIndex
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
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagePart as DamagePart
import qualified Parun.Types.DealDamage as DealDamage
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
import qualified Parun.Types.Face as Face
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.GrantedAbility as GrantedAbility
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.IfTaken as IfTaken
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.KeywordFamily as KeywordFamily
import qualified Parun.Types.Layout as Layout
import qualified Parun.Types.LibraryPlacement as LibraryPlacement
import qualified Parun.Types.LibraryPosition as LibraryPosition
import qualified Parun.Types.LifeLoss as LifeLoss
import qualified Parun.Types.LifeLossCause as LifeLossCause
import qualified Parun.Types.ManaAddition as ManaAddition
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaProduction as ManaProduction
import qualified Parun.Types.ManaRetention as ManaRetention
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Mill as Mill
import qualified Parun.Types.Modal as Modal
import qualified Parun.Types.Mode as Mode
import qualified Parun.Types.ModeSelection as ModeSelection
import qualified Parun.Types.Modification as Modification
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness
import qualified Parun.Types.ModifyTarget as ModifyTarget
import qualified Parun.Types.MoveToZone as MoveToZone
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Optionality as Optionality
import qualified Parun.Types.OrElse as OrElse
import qualified Parun.Types.OwnedZone as OwnedZone
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
import qualified Parun.Types.PreventNextDamage as PreventNextDamage
import qualified Parun.Types.PrintedReplacement as PrintedReplacement
import qualified Parun.Types.Protection as Protection
import qualified Parun.Types.PutCounters as PutCounters
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RandomCardInHand as RandomCardInHand
import qualified Parun.Types.Regenerability as Regenerability
import qualified Parun.Types.Replace as Replace
import qualified Parun.Types.ReplacementEffect as ReplacementEffect
import qualified Parun.Types.ReplacementOrigin as ReplacementOrigin
import qualified Parun.Types.RuleAbilities as RuleAbilities
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
import qualified Parun.Types.Supertype as Supertype
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TargetCount as TargetCount
import qualified Parun.Types.TargetSlot as TargetSlot
import qualified Parun.Types.TheseDiscard as TheseDiscard
import qualified Parun.Types.Times as Times
import qualified Parun.Types.Together as Together
import qualified Parun.Types.Toughness as Toughness
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TriggerLimit as TriggerLimit
import qualified Parun.Types.TriggeredAbility as TriggeredAbility
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.TypeLine as TypeLine
import qualified Parun.Types.Uses as Uses
import qualified Parun.Types.Ward as Ward
import qualified Parun.Types.Zone as Zone
import qualified Parun.Types.ZoneScope as ZoneScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Oracle" $ do
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
        arc = spell [clause [Effect.DealDamage (DealDamage.MkDealDamage (Seq.singleton (DamagePart.MkDamagePart (ObjectRef.InSlot target) (Quantity.Share target))) Nothing Nothing Nothing)]] [(target, slot)]
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
    Spec.assertEq s [[Text.pack "Draw two cards."]] (Oracle.abilities divination)
    let craving = spell [clause [draw (PlayerRef.Relative PlayerRelation.You) 3, loseLife (PlayerRef.Relative PlayerRelation.You) 3]] []
    Spec.assertEq s (Just (Text.pack "You draw three cards and you lose 3 life.")) (Oracle.render craving)
    Spec.assertEq s [[Text.pack "You draw three cards and you lose 3 life.", Text.pack "You draw three cards and lose 3 life.", Text.pack "Draw three cards, then lose 3 life."]] (Oracle.abilities craving)
    let insurance = spell [clause [loseLife (PlayerRef.InSlot target) 2, draw (PlayerRef.Relative PlayerRelation.You) 1]] [(target, TargetSlot.required Pool.Players Nothing)]
    Spec.assertEq s [[Text.pack "Target player loses 2 life. Draw a card.", Text.pack "Target player loses 2 life.\nDraw a card.", Text.pack "Target player loses 2 life. Then draw a card.", Text.pack "Target player loses 2 life and you draw a card."]] (Oracle.abilities insurance)

  -- CR 113.2c / 113.3a: text pairs with a card's abilities as a multiset, each
  -- ability in one of its own wordings, and a spell's instructions are one
  -- ability even across paragraphs (Bargain).
  Spec.it s "says matches each ability against its own wordings" $ do
    let ring = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis]) (addMana 1)
        tomb = ring {ActivatedAbility.modal = payload [clause [addMana 1, damage [(you, 2)]]] []}
        insurance = payload [clause [loseLife (PlayerRef.InSlot target) 2, draw (PlayerRef.Relative PlayerRelation.You) 1]] [(target, TargetSlot.required Pool.Players Nothing)]
        both = withFace (\f -> f {Face.keywords = Map.fromList [(Keyword.Flying, 1), (Keyword.Vigilance, 1)], Face.activatedAbilities = [tomb], Face.spell = insurance})
        rest = "Target player loses 2 life.\nDraw a card.\n{T}: Add {G}. Then Spark deals 2 damage to you.\n"
    Spec.assertEq s [1, 1, 4, 2] (fmap length (Oracle.abilities both))
    Spec.assertEq s (Just (Text.pack "Flying\nVigilance\nTarget player loses 2 life. Draw a card.\n{T}: Add {G}. Spark deals 2 damage to you.")) (Oracle.render both)
    Spec.assertBool s (Oracle.says both spark (Text.pack (rest <> "Flying, vigilance"))) "every ability unsaid"
    Spec.assertBool s (not (Oracle.says both spark (Text.pack (rest <> "Flying")))) "an ability left out said"
    Spec.assertBool s (not (Oracle.says both spark (Text.pack (rest <> "Flying, vigilance, trample")))) "an ability added said"
    let partly = withFace (\f -> f {Face.keywords = Map.singleton Keyword.Flying 1, Face.activatedAbilities = [tomb], Face.minimumX = 1})
    Spec.assertEq s Nothing (Oracle.render partly)
    Spec.assertBool s (not (Oracle.says partly spark (Text.pack "Flying\n{T}: Add {G}. Spark deals 2 damage to you."))) "a card not rendered in full said"

  -- A second instruction for the same player drops the subject; for another
  -- player it is joined by "and" (Vampiric Feast), starts a sentence (Soul
  -- Shred), one opened by "Then" (Return of the Nightstalkers), or starts a
  -- paragraph (Bargain), as printings differ, "and" first.
  Spec.it s "render strings a clause's instructions together" $ do
    let sign = spell [clause [draw (PlayerRef.InSlot target) 2, loseLife (PlayerRef.InSlot target) 2]] [(target, TargetSlot.required Pool.Players Nothing)]
    Spec.assertEq s [[Text.pack "Target player draws two cards and loses 2 life.", Text.pack "Target player draws two cards, then loses 2 life."]] (Oracle.abilities sign)
    let feast = spell [clause [damage [(target, 4)], gainLife 4]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s (Just (Text.pack "Spark deals 4 damage to any target and you gain 4 life.")) (Oracle.render feast)
    Spec.assertEq s [[Text.pack "Spark deals 4 damage to any target and you gain 4 life.", Text.pack "Spark deals 4 damage to any target. You gain 4 life.", Text.pack "Spark deals 4 damage to any target.\nYou gain 4 life.", Text.pack "Spark deals 4 damage to any target. Then you gain 4 life."]] (Oracle.abilities feast)

  -- CR 601.2c: each target slot is announced once, so text naming a slot
  -- twice, or never, is not the mode's; a later instruction names it again
  -- only by a pronoun, which "any target" has none of.
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
    Spec.assertEq s [[Text.pack "Spark deals 1 damage to any target and 1 damage to you."]] (Oracle.abilities brothers)
    let tomb = ring {ActivatedAbility.modal = payload [clause [addMana 1, damage [(you, 2)]]] []}
    Spec.assertEq s [[Text.pack "{T}: Add {G}. Spark deals 2 damage to you.", Text.pack "{T}: Add {G}. Then Spark deals 2 damage to you."]] (Oracle.abilities (withFace (\f -> f {Face.activatedAbilities = [tomb]})))
    let earthquake = spell [clause [Effect.DealDamage (DealDamage.MkDealDamage (Seq.fromList [DamagePart.MkDamagePart (ObjectRef.EachMatching (Filter.HasCardType CardType.Creature)) (Quantity.Literal 2), DamagePart.MkDamagePart ObjectRef.EachPlayer (Quantity.Literal 2)]) Nothing Nothing Nothing)]] []
    Spec.assertEq s [[Text.pack "Spark deals 2 damage to each creature and each player."]] (Oracle.abilities earthquake)
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
    Spec.assertEq s [[Text.pack "When Spark enters, it deals 2 damage to target creature.", Text.pack "When Spark enters, Spark deals 2 damage to target creature."]] (Oracle.abilities (withFace (\f -> f {Face.triggeredAbilities = [imp]})))
    let star = triggered TriggerCondition.SelfDies [clause [draw (PlayerRef.Relative PlayerRelation.You) 1]] []
    Spec.assertEq s [[Text.pack "When Spark dies, draw a card.", Text.pack "When Spark dies, you draw a card."]] (Oracle.abilities (withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [star]})))
    Spec.assertEq s [[Text.pack "When Spark is put into a graveyard from the battlefield, draw a card.", Text.pack "When Spark is put into a graveyard from the battlefield, you draw a card."]] (Oracle.abilities (withFace (\f -> (typed [CardType.Artifact] [] f) {Face.triggeredAbilities = [star]})))

  -- CR 603.2b: "At the beginning of [step]", in whose turns the scope says;
  -- the active player the event binds is "that player". Every turn's upkeep
  -- and end step are free, the modern wording first.
  Spec.it s "render prints a trigger at the beginning of a step" $ do
    let at phase scope effects = withFace (\f -> f {Face.triggeredAbilities = [triggered (TriggerCondition.StepBegins (StepBegins.MkStepBegins phase Nothing scope)) [clause effects] []]})
        upkeep = Phase.Beginning BeginningStep.Upkeep
        end = Phase.Ending EndingStep.EndStep
    Spec.assertEq s (Just (Text.pack "At the beginning of your upkeep, you gain 1 life.")) (Oracle.render (at upkeep TurnScope.ControllersTurn [gainLife 1]))
    Spec.assertEq s [[Text.pack "At the beginning of each player's upkeep, that player draws a card.", Text.pack "At the beginning of each upkeep, that player draws a card."]] (Oracle.abilities (at upkeep TurnScope.EachTurn [draw (PlayerRef.InSlot thatPlayer) 1]))
    Spec.assertEq s (Just (Text.pack "At the beginning of combat on your turn, you gain 1 life.")) (Oracle.render (at (Phase.Combat CombatStep.BeginningOfCombat) TurnScope.ControllersTurn [gainLife 1]))
    Spec.assertEq s [[Text.pack "At the beginning of each end step, sacrifice Spark.", Text.pack "At the beginning of the end step, sacrifice Spark.", Text.pack "At the beginning of each player's end step, sacrifice Spark."]] (Oracle.abilities (at end TurnScope.EachTurn [sacrifice]))
    Spec.assertEq s (Just (Text.pack "At the beginning of each opponent's end step, Spark deals 1 damage to that player.")) (Oracle.render (at end TurnScope.OpponentsTurn [damage [(thatPlayer, 1)]]))

  -- CR 508.3a / 509.3a / 510.1: the source's combat events, which can recur
  -- and so open with "Whenever", or "When" on a source that destroys itself
  -- (Loyal Sentry); the defending player and the creature it blocks are named
  -- as the event names them. Once named, the source is "it" or its name.
  Spec.it s "render prints a trigger on attacking, blocking and combat damage" $ do
    let on event effects = withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [triggered event [clause effects] []]})
    Spec.assertEq s [[Text.pack "Whenever Spark attacks, defending player discards a card.", Text.pack "When Spark attacks, defending player discards a card."]] (Oracle.abilities (on (TriggerCondition.SelfAttacks TriggerFrequency.EveryTime) [discard (PlayerRef.InSlot thatPlayer) 1]))
    let raiders = on (TriggerCondition.SelfDealsCombatDamageToPlayer PlayerRelation.Opponent) [discard (PlayerRef.InSlot thatPlayer) 1]
    Spec.assertEq s (Just (Text.pack "Whenever Spark deals combat damage to an opponent, that player discards a card.")) (Oracle.render raiders)
    Spec.assertBool s (Oracle.says raiders spark (Text.pack "Whenever this creature deals combat damage to an opponent, that opponent discards a card.")) "that opponent unsaid"
    let sentry = on (TriggerCondition.SelfBlocksCreature (Filter.HasCardType CardType.Creature)) [destroy (ObjectRef.InSlot thatAttacker) Regenerability.Regenerable, destroy (ObjectRef.InSlot self) Regenerability.Regenerable]
    Spec.assertEq s (Just (Text.pack "Whenever Spark blocks a creature, destroy that creature and it.")) (Oracle.render sentry)
    Spec.assertBool s (Oracle.says sentry spark (Text.pack "When this creature blocks a creature, destroy that creature and this creature.")) "Loyal Sentry's wording unsaid"
    Spec.assertBool s (Oracle.says sentry spark (Text.pack "When this creature blocks a creature, destroy both creatures.")) "Alaborn Zealot's wording unsaid"
    let roc = on (TriggerCondition.SelfBlocksCreature (Filter.And [Filter.HasCardType CardType.Creature, Filter.Not (Filter.HasKeyword Keyword.Flying)])) [modify (ObjectRef.InSlot self) Duration.UntilEndOfTurn (pt 1 0)]
    Spec.assertEq s (Just (Text.pack "Whenever Spark blocks a creature without flying, it gets +1/+0 until end of turn.")) (Oracle.render roc)
    Spec.assertBool s (Oracle.says roc spark (Text.pack "Whenever this creature blocks a creature without flying, this creature gets +1/+0 until end of turn.")) "the name after the event unsaid"
    Spec.assertEq s (Just (Text.pack "Whenever Spark enters or attacks, you gain 1 life.")) (Oracle.render (on (TriggerCondition.AnyOf [TriggerCondition.SelfEnters, TriggerCondition.SelfAttacks TriggerFrequency.EveryTime]) [gainLife 1]))
    let raptor = on (TriggerCondition.IsDealtDamage ActingPermanent.Self) [gainLifeBy (Quantity.InSlot (SlotName.MkSlotName (Text.pack "thatMuch")))]
    Spec.assertEq s (Just (Text.pack "Whenever Spark is dealt damage, you gain that much life.")) (Oracle.render raptor)
    Spec.assertBool s (Oracle.says raptor spark (Text.pack "Enrage \8212 Whenever this creature is dealt damage, you gain that much life.")) "enrage unsaid"

  -- CR 603.6a / 700.4 read by a bystander: "Whenever a [type] enters" or
  -- "dies", the object "it" or "that creature"; landfall's ability word
  -- (CR 207.2c); a creature among the objects it watches named first
  -- (Zulaport Cutthroat), never a noncreature.
  Spec.it s "render prints a trigger on another object entering or dying" $ do
    let on types event effects = withFace (\f -> (typed types [] f) {Face.triggeredAbilities = [triggered event [clause effects] []]})
        others = Filter.And [Filter.HasCardType CardType.Creature, Filter.Not Filter.IsSource]
        mine = Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You]
    Spec.assertEq s (Just (Text.pack "Whenever another creature enters, you gain 1 life.")) (Oracle.render (on [CardType.Creature] (TriggerCondition.PermanentEnters others) [gainLife 1]))
    Spec.assertEq s [[Text.pack "Whenever a creature enters, Spark deals 2 damage to it.", Text.pack "Whenever a creature enters, Spark deals 2 damage to that creature."]] (Oracle.abilities (on [CardType.Enchantment] (TriggerCondition.PermanentEnters (Filter.HasCardType CardType.Creature)) [damageBy [(ObjectRef.InSlot became, Quantity.Literal 2)]]))
    Spec.assertEq s (Just (Text.pack "Landfall \8212 Whenever a land you control enters, you gain 1 life.")) (Oracle.render (on [CardType.Creature] (TriggerCondition.PermanentEnters (Filter.And [Filter.HasCardType CardType.Land, Filter.ControlledBy PlayerRelation.You])) [gainLife 1]))
    Spec.assertEq s [[Text.pack "Whenever a creature you control dies, you gain 1 life.", Text.pack "Whenever Spark or another creature you control dies, you gain 1 life."]] (Oracle.abilities (on [CardType.Creature] (TriggerCondition.PermanentDies mine) [gainLife 1]))
    Spec.assertEq s [[Text.pack "Whenever a creature you control dies, you gain 1 life."]] (Oracle.abilities (on [CardType.Artifact] (TriggerCondition.PermanentDies mine) [gainLife 1]))
    let dragon = on [CardType.Creature] (TriggerCondition.SelfPutFromBattlefieldInto (OwnedZone.MkOwnedZone Zone.Graveyard PlayerRelation.You)) [Effect.MoveToZone (move (ObjectRef.InSlot became) Zone.Hand)]
    Spec.assertEq s (Just (Text.pack "When Spark is put into your graveyard from the battlefield, return it to your hand.")) (Oracle.render dragon)
    -- The card the source became is yours to return from your graveyard;
    -- another creature's is not.
    let returned = Effect.MoveToZone ((move (ObjectRef.InSlot became) Zone.Hand) {MoveToZone.origin = Just Zone.Graveyard})
    Spec.assertEq s (Just (Text.pack "When Spark dies, return it from your graveyard to your hand.")) (Oracle.render (on [CardType.Creature] TriggerCondition.SelfDies [returned]))
    Spec.assertEq s Nothing (Oracle.render (on [CardType.Creature] (TriggerCondition.PermanentDies mine) [returned]))

  -- CR 603.4: "[When/Whenever/At] [event], if [condition], [effect]", the
  -- condition a count of cards in a hand or of permanents, the source's
  -- status, or a player's life; hellbent's and raid's ability words (CR
  -- 207.2c) free.
  Spec.it s "render prints an intervening if clause" $ do
    let endStep = TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Ending EndingStep.EndStep) Nothing TurnScope.ControllersTurn)
        upkeeps scope = TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Beginning BeginningStep.Upkeep) Nothing scope)
        gated event condition effects = withFace (\f -> f {Face.triggeredAbilities = [(triggered event [clause effects] []) {TriggeredAbility.intervening = Just condition}]})
        compares q c k = Condition.Compares (Compares.MkCompares q c (Quantity.Literal k))
        hand who = countOf (Filter.And []) (InZone.MkInZone Zone.Hand who)
        academy = gated endStep (compares (hand (PlayerRef.Relative PlayerRelation.You)) Comparison.Exactly 0) [draw (PlayerRef.Relative PlayerRelation.You) 1]
    Spec.assertEq s [[Text.pack "At the beginning of your end step, if you have no cards in hand, draw a card.", Text.pack "At the beginning of your end step, if you have no cards in hand, you draw a card.", Text.pack "Hellbent \8212 At the beginning of your end step, if you have no cards in hand, draw a card.", Text.pack "Hellbent \8212 At the beginning of your end step, if you have no cards in hand, you draw a card."]] (Oracle.abilities academy)
    let raided = gated endStep (compares (Quantity.AttackersDeclaredThisTurn (PlayerRef.Relative PlayerRelation.You)) Comparison.AtLeast 1) [draw (PlayerRef.Relative PlayerRelation.You) 1]
    Spec.assertEq s [[Text.pack "At the beginning of your end step, if you attacked this turn, draw a card.", Text.pack "At the beginning of your end step, if you attacked this turn, you draw a card.", Text.pack "Raid \8212 At the beginning of your end step, if you attacked this turn, draw a card.", Text.pack "Raid \8212 At the beginning of your end step, if you attacked this turn, you draw a card."]] (Oracle.abilities raided)
    Spec.assertEq s (Just (Text.pack "At the beginning of each opponent's upkeep, if that player has seven or more cards in hand, Spark deals 4 damage to that player.")) (Oracle.render (gated (upkeeps TurnScope.OpponentsTurn) (compares (hand (PlayerRef.InSlot thatPlayer)) Comparison.AtLeast 7) [damage [(thatPlayer, 4)]]))
    Spec.assertEq s [[Text.pack "At the beginning of your upkeep, if there are no Zombies on the battlefield, you gain 1 life.", Text.pack "At the beginning of your upkeep, if no Zombies are on the battlefield, you gain 1 life."]] (Oracle.abilities (gated (upkeeps TurnScope.ControllersTurn) (compares (countOf (Filter.HasSubtype Subtype.Zombie) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) Comparison.Exactly 0) [gainLife 1]))
    Spec.assertEq s (Just (Text.pack "At the beginning of your upkeep, if you control no other creatures, you gain 1 life.")) (Oracle.render (gated (upkeeps TurnScope.ControllersTurn) (compares (countOf (Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You, Filter.Not Filter.IsSource]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) Comparison.Exactly 0) [gainLife 1]))
    Spec.assertEq s (Just (Text.pack "At the beginning of each player's upkeep, if Spark is untapped, that player draws a card.")) (Oracle.render (gated (upkeeps TurnScope.EachTurn) (compares (countOf (Filter.And [Filter.IsSource, Filter.Not Filter.IsTapped]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) Comparison.AtLeast 1) [draw (PlayerRef.InSlot thatPlayer) 1]))
    Spec.assertEq s (Just (Text.pack "At the beginning of your upkeep, if you have 40 or more life, you gain 1 life.")) (Oracle.render (gated (upkeeps TurnScope.ControllersTurn) (compares (Quantity.LifeTotal (PlayerRef.Relative PlayerRelation.You)) Comparison.AtLeast 40) [gainLife 1]))

  -- A creature type names creatures alone ("target attacking Goblin you
  -- control", Boggart Prankster); a change to each of several objects reads
  -- together or one at a time (Zhang He, Wei General); a player a slot names
  -- owns "their" graveyard once named (Guiltfeeder).
  Spec.it s "render names creatures by type and counts in a named player's zone" $ do
    let prankster = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 1 0)]] [(target, TargetSlot.required Pool.Creatures (Just (Filter.And [Filter.IsAttacking, Filter.HasSubtype Subtype.Goblin, Filter.ControlledBy PlayerRelation.You])))]
    Spec.assertEq s (Just (Text.pack "Target attacking Goblin you control gets +1/+0 until end of turn.")) (Oracle.render prankster)
    let he = spell [clause [modify (ObjectRef.EachMatching (Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You, Filter.Not Filter.IsSource])) Duration.UntilEndOfTurn (pt 1 0)]] []
    Spec.assertEq s (Just (Text.pack "Other creatures you control get +1/+0 until end of turn.")) (Oracle.render he)
    Spec.assertBool s (Oracle.says he spark (Text.pack "Each other creature you control gets +1/+0 until end of turn.")) "each unsaid"
    let feeder = withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [triggered TriggerCondition.SelfAttacksUnblocked [clause [Effect.LoseLife (LifeLoss.MkLifeLoss (PlayerRef.InSlot thatPlayer) (countOf (Filter.And []) (InZone.MkInZone Zone.Graveyard (PlayerRef.InSlot thatPlayer))) LifeLossCause.ByEffect Nothing)]] []]})
    Spec.assertEq s (Just (Text.pack "Whenever Spark attacks and isn't blocked, defending player loses 1 life for each card in that player's graveyard.")) (Oracle.render feeder)
    Spec.assertBool s (Oracle.says feeder spark (Text.pack "Whenever this creature attacks and isn't blocked, defending player loses 1 life for each card in their graveyard.")) "their unsaid"

  -- An activated ability whose cost sacrifices its source calls it "it"
  -- (Mogg Mob).
  Spec.it s "render calls a sacrificed source it" $ do
    let mob = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.SacrificeThis]) (damage [(you, 3)])
    Spec.assertEq s [[Text.pack "Sacrifice Spark: It deals 3 damage to you."]] (Oracle.abilities (withFace (\f -> f {Face.activatedAbilities = [mob]})))

  -- CR 113.2c: a paragraph break starts another ability, so only a spell's
  -- instructions (one spell ability, CR 113.3a) may be broken across lines.
  Spec.it s "render keeps a triggered ability's sentences in one paragraph" $ do
    let slots = [(target, TargetSlot.required Pool.Creatures Nothing)]
        apart = triggered TriggerCondition.SelfEnters [clause [damage [(target, 2)]], clause [gainLife 2]] slots
        together = triggered TriggerCondition.SelfEnters [clause [damage [(target, 2)], gainLife 2]] slots
    Monad.forM_ [apart, together] $ \t -> do
      let rendered = concat (Oracle.abilities (withFace (\f -> f {Face.triggeredAbilities = [t]})))
      Spec.assertBool s (not (null rendered)) "no rendering"
      Spec.assertEq s [] (filter (Text.isInfixOf (Text.pack "\n")) rendered)

  -- Protections share a line (Paladin en-Vec); a disjunction of colours reads
  -- "and/or" in the plural (Ignite Disorder), of other adjectives "or" (Fire at
  -- Will), of card types "and" (Devastation).
  Spec.it s "render shares a line of protections and pluralises a disjunction" $ do
    let from c = Keyword.Protection (Protection.MkProtection (Filter.HasColor c) Nothing)
    Spec.assertEq s [[Text.pack "Protection from black and from red"]] (Oracle.abilities (card Layout.Normal [[from Color.Black, from Color.Red]]))
    let devastation = spell [clause [destroy (ObjectRef.EachMatching (Filter.Or [Filter.HasCardType CardType.Creature, Filter.HasCardType CardType.Land])) Regenerability.Regenerable]] []
    Spec.assertEq s (Just (Text.pack "Destroy all creatures and lands.")) (Oracle.render devastation)
    let colours = Filter.Or [Filter.HasColor Color.White, Filter.HasColor Color.Blue]
        ignite = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Creatures (Just colours)) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s [[Text.pack "Destroy two target white and/or blue creatures."]] (Oracle.abilities ignite)
    let combatants = Filter.Or [Filter.IsAttacking, Filter.IsBlocking]
        fire = spell [clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable]] [(target, (TargetSlot.required Pool.Creatures (Just combatants)) {TargetSlot.count = SlotCount.Printed (TargetCount.MkTargetCount 2 (Just 2))})]
    Spec.assertEq s [[Text.pack "Destroy two target attacking or blocking creatures."]] (Oracle.abilities fire)

  -- CR 611.2a: a change to an object "until end of turn", the duration ending
  -- the sentence (Giant Growth) or opening it (Aspirant's Ascent), ending it
  -- first; with no duration stated it lasts indefinitely (Riding the Dilu
  -- Horse).
  Spec.it s "render prints a change to power and toughness and its duration" $ do
    let growth = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 3 3)]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s (Just (Text.pack "Target creature gets +3/+3 until end of turn.")) (Oracle.render growth)
    Spec.assertEq s [[Text.pack "Target creature gets +3/+3 until end of turn.", Text.pack "Until end of turn, target creature gets +3/+3."]] (Oracle.abilities growth)
    let horse = spell [clause [modify (ObjectRef.InSlot target) Duration.Indefinite (pt 2 2), modify (ObjectRef.InSlot target) Duration.Indefinite (Modification.GainKeyword Keyword.Horsemanship)]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s [[Text.pack "Target creature gets +2/+2 and gains horsemanship."]] (Oracle.abilities horse)

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
    let itself = ObjectRef.InSlot self
        changes = [Modification.LoseKeyword Keyword.Shroud, Modification.GainKeyword Keyword.FirstStrike, Modification.GainKeyword Keyword.Deathtouch]
        blade = spell [clause (fmap (modify itself Duration.UntilEndOfTurn) changes)] []
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
        to zone slots = concat (Oracle.abilities (spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) zone)]] slots))
    Spec.assertEq s [Text.pack "Return target creature to its owner's hand."] (to Zone.Hand creature)
    Spec.assertEq s [Text.pack "Return target creature card from your graveyard to your hand."] (to Zone.Hand mine)
    Spec.assertEq s [Text.pack "Exile target creature."] (to Zone.Exile creature)
    Spec.assertEq s [Text.pack "Put target creature on the bottom of its owner's library."] (to Zone.Library creature)
    Spec.assertEq s [Text.pack "Return target creature card from your graveyard to the battlefield."] (to Zone.Battlefield mine)
    Spec.assertEq s [] (to Zone.Battlefield creature)
    let tapped = (move (ObjectRef.InSlot target) Zone.Battlefield) {MoveToZone.riders = EntryRiders.defaultValue {EntryRiders.tapped = TapState.Tapped}}
    Spec.assertEq s [[Text.pack "Return target creature card from your graveyard to the battlefield tapped."]] (Oracle.abilities (spell [clause [Effect.MoveToZone tapped]] mine))
    let placed placement = concat (Oracle.abilities (spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) Zone.Library) {MoveToZone.placement = placement}]] creature))
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
    Spec.assertEq s [[Text.pack "Return all creatures to their owners' hands.", Text.pack "Return all creatures to their owner's hand.", Text.pack "Return each creature to its owner's hand."]] (Oracle.abilities evacuation)

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
    Spec.assertEq s [[Text.pack "Put a +1/+1 counter on each of up to two target creatures.", Text.pack "Support 2."]] (Oracle.abilities (spell [clause [instruction]] [(target, upTo 2 Nothing)]))
    let ability slot = withFace (\f -> f {Face.activatedAbilities = [(activated (Cost.MkCost (Just (ManaCost.MkManaCost [green])) []) instruction) {ActivatedAbility.modal = payload [clause [instruction]] [(target, slot)]}]})
    Spec.assertEq s [[Text.pack "{G}: Put a +1/+1 counter on each of up to two other target creatures.", Text.pack "{G}: Support 2."]] (Oracle.abilities (ability (upTo 2 (Just (Filter.Not Filter.IsSource)))))
    Spec.assertEq s [[Text.pack "{G}: Put a +1/+1 counter on each of up to two target creatures."]] (Oracle.abilities (ability (upTo 2 Nothing)))

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
    Spec.assertBool s (elem (Text.pack "Draw a card, then discard a card.") (concat (Oracle.abilities loot))) "no \", then\""

  -- CR 615.7: a shield preventing the next damage this turn.
  Spec.it s "render prints a prevention shield" $ do
    let shield kind ref = Effect.PreventNextDamage (PreventNextDamage.MkPreventNextDamage Duration.UntilEndOfTurn kind (Just ref) Nothing Nothing Nothing (Quantity.Literal 3) Seq.empty)
    Spec.assertEq s (Just (Text.pack "Prevent the next 3 damage that would be dealt to any target this turn.")) (Oracle.render (spell [clause [shield Nothing (ObjectRef.InSlot target)]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]))
    Spec.assertEq s (Just (Text.pack "Prevent the next 3 combat damage that would be dealt to you this turn.")) (Oracle.render (spell [clause [shield (Just DamageKind.Combat) (ObjectRef.InSlot you)]] []))

  -- CR 608.2h: a count reads "for each" object or "equal to the number of"
  -- them, as printings differ (Fruition, Clearwater Goblet; Theft of Dreams,
  -- Dream Salvage), "for each" first; permanents nothing else places are "on
  -- the battlefield", and a factor reads before "for each" (Gerrard's Wisdom).
  Spec.it s "render counts objects for each or equal to their number" $ do
    let forests = countOf (Filter.HasSubtype Subtype.Forest) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
    Spec.assertEq s [[Text.pack "You gain 1 life for each Forest on the battlefield.", Text.pack "You gain life equal to the number of Forests on the battlefield."]] (Oracle.abilities (spell [clause [gainLifeBy forests]] []))
    let hand = countOf (Filter.And []) (InZone.MkInZone Zone.Hand (PlayerRef.Relative PlayerRelation.You))
    Spec.assertEq s [[Text.pack "You gain 2 life for each card in your hand."]] (Oracle.abilities (spell [clause [gainLifeBy (Quantity.Arithmetic (Arithmetic.Times (Times.MkTimes 2 hand)))]] []))
    let tapped = countOf (Filter.And [Filter.HasCardType CardType.Creature, Filter.IsTapped, Filter.ControlledByBound target]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
        opponent = [(target, TargetSlot.required Pool.Players (Just (Filter.IsPlayer PlayerRelation.Opponent)))]
    Spec.assertEq s [[Text.pack "Draw a card for each tapped creature target opponent controls.", Text.pack "Draw cards equal to the number of tapped creatures target opponent controls."]] (Oracle.abilities (spell [clause [Effect.Draw (Draw.MkDraw (PlayerRef.Relative PlayerRelation.You) tapped Nothing)]] opponent))
    let swamps = countOf (Filter.And [Filter.HasSubtype Subtype.Swamp, Filter.ControlledBy PlayerRelation.You]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
        coffers = activated (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])) [CostComponent.TapThis]) (Effect.AddMana (ManaAddition.MkManaAddition (PlayerRef.Relative PlayerRelation.You) (ManaProduction.OfType (ManaType.Colored Color.Black)) swamps ManaRetention.Ordinary Nothing Nothing Nothing))
    Spec.assertEq s [[Text.pack "{2}, {T}: Add {B} for each Swamp you control."]] (Oracle.abilities (withFace (\f -> f {Face.activatedAbilities = [coffers]})))
    let theirs = countOf (Filter.HasCardType CardType.Creature) (InZone.MkInZone Zone.Graveyard PlayerRef.Candidate)
    Spec.assertEq s (Just (Text.pack "Each player draws a card for each creature card in their graveyard.")) (Oracle.render (spell [clause [Effect.Draw (Draw.MkDraw (PlayerRef.Relative PlayerRelation.AnyPlayer) theirs Nothing)]] []))

  -- CR 120.1: damage reads "equal to" a count after its recipients (Rockslide
  -- Ambush) and a characteristic before them (Soul's Fire), each also the
  -- other way, as printings differ; a player's lands are the ones "they
  -- control" (Acidic Soil).
  Spec.it s "render deals damage equal to a number" $ do
    let mountains = countOf (Filter.And [Filter.HasSubtype Subtype.Mountain, Filter.ControlledBy PlayerRelation.You]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
        ambush = spell [clause [damageBy [(ObjectRef.InSlot target, mountains)]]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s [[Text.pack "Spark deals damage to target creature equal to the number of Mountains you control.", Text.pack "Spark deals damage equal to the number of Mountains you control to target creature."]] (Oracle.abilities ambush)
    let theirs = countOf (Filter.And [Filter.HasCardType CardType.Land, Filter.ControlledByRecipient]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
    Spec.assertEq s (Just (Text.pack "Spark deals damage to each player equal to the number of lands they control.")) (Oracle.render (spell [clause [damageBy [(ObjectRef.EachPlayer, theirs)]]] []))
    let dealer = SlotName.MkSlotName (Text.pack "dealer")
        fire = Effect.DealDamage (DealDamage.MkDealDamage (Seq.singleton (DamagePart.MkDamagePart (ObjectRef.InSlot target) (powerOf dealer))) (Just dealer) Nothing Nothing)
        slots = [(dealer, TargetSlot.required Pool.Creatures (Just (Filter.ControlledBy PlayerRelation.You))), (target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s [[Text.pack "Target creature you control deals damage equal to its power to any target.", Text.pack "Target creature you control deals damage to any target equal to its power."]] (Oracle.abilities (spell [clause [fire]] slots))
    let victim f = [(dealer, TargetSlot.required Pool.Creatures (Just (Filter.ControlledBy PlayerRelation.You))), (target, TargetSlot.required Pool.Creatures (Just f))]
    Spec.assertEq s (Just (Text.pack "Target creature you control deals damage equal to its power to another target creature.")) (Oracle.render (spell [clause [fire]] (victim (Filter.Not (Filter.IsBound dealer)))))
    Spec.assertEq s (Just (Text.pack "Target creature you control deals damage equal to its power to target creature you don't control.")) (Oracle.render (spell [clause [fire]] (victim (Filter.Not (Filter.ControlledBy PlayerRelation.You)))))
    let eater = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis]) (damageBy [(ObjectRef.InSlot target, Quantity.Measure Measure.Power)])
    Spec.assertEq s (Just (Text.pack "{T}: Spark deals damage equal to its power to any target.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [eater {ActivatedAbility.modal = payload [clause [damageBy [(ObjectRef.InSlot target, Quantity.Measure Measure.Power)]]] [(target, TargetSlot.required Pool.AnyTarget Nothing)]}]})))

  -- CR 208.1 / 601.2c: a target's characteristic is "its" once the target is
  -- named (Swords to Plowshares), and names the target where nothing else
  -- does (Soul's Majesty).
  Spec.it s "render reads a target's characteristic as its own" $ do
    let mine = [(target, TargetSlot.required Pool.Creatures (Just (Filter.ControlledBy PlayerRelation.You)))]
        majesty = spell [clause [Effect.Draw (Draw.MkDraw (PlayerRef.Relative PlayerRelation.You) (powerOf target) Nothing)]] mine
    Spec.assertEq s [[Text.pack "Draw cards equal to the power of target creature you control."]] (Oracle.abilities majesty)
    let plowshares = spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) Zone.Exile), Effect.GainLife (PlayerQuantity.MkPlayerQuantity (PlayerRef.ControllerOfBound target) (powerOf target))]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertBool s (elem (Text.pack "Exile target creature. Its controller gains life equal to its power.") (concat (Oracle.abilities plowshares))) "no \"its power\""

  -- CR 107.3: a change that counts reads "for each" (Empyrial Armor) or "+X"
  -- with what X is (Inner Calm, Outer Strength), "for each" first; a change by
  -- the target's own power is written as doubling is (#5486).
  Spec.it s "render prints a change to power and toughness that counts" $ do
    let hand = countOf (Filter.And []) (InZone.MkInZone Zone.Hand (PlayerRef.Relative PlayerRelation.You))
        creature = [(target, TargetSlot.required Pool.Creatures Nothing)]
        calm = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (ptBy hand hand)]] creature
    Spec.assertEq s (Just (Text.pack "Target creature gets +1/+1 until end of turn for each card in your hand.")) (Oracle.render calm)
    Spec.assertBool s (Oracle.says calm (CardName.MkCardName (Text.pack "Spark")) (Text.pack "Target creature gets +X/+X until end of turn, where X is the number of cards in your hand.")) "no \"where X is\""
    let artifacts = countOf (Filter.And [Filter.HasCardType CardType.Artifact, Filter.ControlledBy PlayerRelation.You]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
    Spec.assertEq s (Just (Text.pack "Spark gets +1/+0 for each artifact you control.")) (Oracle.render (withFace (\f -> f {Face.staticAbilities = [static (Affected.Matching Filter.IsSource) [ptBy artifacts (Quantity.Literal 0)]]})))
    Spec.assertEq s Nothing (Oracle.render (spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (ptBy (powerOf target) (Quantity.Literal 0))]] creature))

  -- CR 604.3 / 208.2: a characteristic-defining ability gives the stars a face
  -- prints, both "each" (Nightmare) or one (Sylvan Yeti).
  Spec.it s "render prints a characteristic-defining power and toughness" $ do
    let swamps = countOf (Filter.And [Filter.HasSubtype Subtype.Swamp, Filter.ControlledBy PlayerRelation.You]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))
        starred p t = withFace (\f -> f {Face.power = Just (Power.MkPower p), Face.toughness = Just (Toughness.MkToughness t), Face.characteristicPT = Just (CharacteristicPT.MkCharacteristicPT swamps swamps)})
    Spec.assertEq s (Just (Text.pack "Spark's power and toughness are each equal to the number of Swamps you control.")) (Oracle.render (starred Quantity.Star Quantity.Star))
    Spec.assertEq s (Just (Text.pack "Spark's power is equal to the number of Swamps you control.")) (Oracle.render (starred Quantity.Star (Quantity.Literal 4)))

  -- CR 111.1 / 122.1: tokens and counters "for each" object counted, or "a
  -- number of" them (Endless Swarm, Tyranid Invasion; Khabal Ghoul, Rhovanion
  -- Rampager), "for each" first.
  Spec.it s "render creates tokens and puts counters by a count" $ do
    let hand = countOf (Filter.And []) (InZone.MkInZone Zone.Hand (PlayerRef.Relative PlayerRelation.You))
        snake = token "Snake Token" [Color.Green] [Subtype.Snake] 1 []
        swarm = Effect.Create (Create.MkCreate hand snake EntryRiders.defaultValue Nothing (PlayerRef.Relative PlayerRelation.You))
    Spec.assertEq s [[Text.pack "Create a 1/1 green Snake creature token for each card in your hand.", Text.pack "Create a number of 1/1 green Snake creature tokens equal to the number of cards in your hand."]] (Oracle.abilities (spell [clause [swarm]] []))
    let opponents = Quantity.Count (Count.MkCount (Scope.OverPlayers (PlayerRef.Relative PlayerRelation.Opponent)) (Filter.And []) Aggregation.Members)
        invasion = Effect.Create (Create.MkCreate opponents snake EntryRiders.defaultValue Nothing (PlayerRef.Relative PlayerRelation.You))
    Spec.assertBool s (Oracle.says (spell [clause [invasion]] []) (CardName.MkCardName (Text.pack "Spark")) (Text.pack "Create a number of 1/1 green Snake creature tokens equal to the number of opponents you have.")) "no \"opponents you have\""
    let ghoul = Effect.PutCounters (PutCounters.MkPutCounters CounterKind.PlusOnePlusOne hand (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "self"))))
    Spec.assertEq s [[Text.pack "Put a +1/+1 counter on Spark for each card in your hand.", Text.pack "Put a number of +1/+1 counters on Spark equal to the number of cards in your hand."]] (Oracle.abilities (spell [clause [ghoul]] []))

  -- CR 118.12: a cost paid on resolution. "Unless" makes the instructions
  -- the branch where it wasn't paid (CR 118.12a), whoever is offered it: the
  -- controller of a spell a slot names, you, or any player. A cost may be
  -- paid "for each" object counted (Rakshasa's Disdain).
  Spec.it s "render prints a cost paid on resolution" $ do
    let spellSlot = [(target, TargetSlot.required Pool.Spells Nothing)]
        counter = Effect.Counter (Counter.MkCounter (ObjectRef.InSlot target) Nothing Nothing Nothing)
        leak = spell [(clause [counter]) {Clause.payGate = Just (gate PayBranch.IfNotPaid (PlayerRef.ControllerOfBound target) (mana [ManaSymbol.Generic 3]))}] spellSlot
    Spec.assertEq s (Just (Text.pack "Counter target spell unless its controller pays {3}.")) (Oracle.render leak)
    let graveyardCards = countOf (Filter.And []) (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You))
        disdain = spell [(clause [counter]) {Clause.payGate = Just ((gate PayBranch.IfNotPaid (PlayerRef.ControllerOfBound target) (mana [ManaSymbol.Generic 1])) {PayGate.perEach = Just graveyardCards})}] spellSlot
    Spec.assertEq s (Just (Text.pack "Counter target spell unless its controller pays {1} for each card in your graveyard.")) (Oracle.render disdain)
    let seer = triggered TriggerCondition.SelfDies [(clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.payGate = Just (gate PayBranch.IfPaid (PlayerRef.InSlot you) (mana [ManaSymbol.Generic 1, ManaSymbol.OfType (ManaType.Colored Color.Blue)]))}] []
    Spec.assertEq s [[Text.pack "When Spark dies, you may pay {1}{U}. If you do, draw a card."]] (Oracle.abilities (withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [seer]})))
    let mountain = Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) (Filter.HasSubtype Subtype.Mountain))]
        upkeep = TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Beginning BeginningStep.Upkeep) Nothing TurnScope.ControllersTurn)
        lithophage = triggered upkeep [(clause [sacrifice]) {Clause.payGate = Just (gate PayBranch.IfNotPaid (PlayerRef.InSlot you) mountain)}] []
    Spec.assertEq s (Just (Text.pack "At the beginning of your upkeep, sacrifice Spark unless you sacrifice a Mountain.")) (Oracle.render (withFace (\f -> f {Face.triggeredAbilities = [lithophage]})))
    let shade = activated (mana [ManaSymbol.OfType (ManaType.Colored Color.Black)]) (modify (ObjectRef.InSlot self) Duration.UntilEndOfTurn (pt 1 1))
        unlessAny = shade {ActivatedAbility.modal = payload [(clause [modify (ObjectRef.InSlot self) Duration.UntilEndOfTurn (pt 1 1)]) {Clause.payGate = Just (gate PayBranch.IfNonePaid (PlayerRef.Relative PlayerRelation.AnyPlayer) (mana [ManaSymbol.Generic 2]))}] []}
    Spec.assertEq s (Just (Text.pack "{B}: Spark gets +1/+1 until end of turn unless any player pays {2}.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [unlessAny]})))
    let blight = triggered TriggerCondition.SelfEnters [(clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.payGate = Just (gate PayBranch.IfPaid (PlayerRef.InSlot you) (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.Blight (CostAmount.Fixed 1)]))}] []
    Spec.assertEq s (Just (Text.pack "When Spark enters, you may blight 1. If you do, draw a card.")) (Oracle.render (withFace (\f -> (typed [CardType.Enchantment] [] f) {Face.triggeredAbilities = [blight]})))
    let goblin = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.DiscardCards (DiscardCards.MkDiscardCards (ObjectCount.Exactly (CostAmount.Fixed 2)) (Filter.HasCardType CardType.Creature))]) (draw (PlayerRef.Relative PlayerRelation.You) 1)
    Spec.assertEq s (Just (Text.pack "Discard two creature cards: Draw a card.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [goblin]})))
    let slate = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.DiscardCards (DiscardCards.MkDiscardCards ObjectCount.Every (Filter.And []))]) (draw (PlayerRef.Relative PlayerRelation.You) 1)
    Spec.assertEq s (Just (Text.pack "Discard your hand: Draw a card.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [slate]})))

  -- CR 608.2c / 608.2d: a clause hanging off the one before it reads with
  -- it: "If you do" after a "may" (Tweeze), "unless you" before one
  -- (Pillaging Horde), and a pair of which you choose one (Twiddle).
  Spec.it s "render strings a clause with the one it hangs off" $ do
    let mayDiscard = (clause [discard (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.optionality = Optionality.Optional (PlayerRef.Relative PlayerRelation.You)}
        ifDone = (clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.ifTaken = Just (IfTaken.AnyTaken (NonEmpty.singleton (ClauseIndex.MkClauseIndex 1)))}
        tweeze = spell [clause [damage [(target, 3)]], mayDiscard, ifDone] [(target, TargetSlot.required Pool.AnyTarget Nothing)]
    Spec.assertEq s (Just (Text.pack "Spark deals 3 damage to any target. You may discard a card. If you do, draw a card.")) (Oracle.render tweeze)
    let notDone = (clause [sacrifice]) {Clause.ifTaken = Just (IfTaken.NoneTaken (NonEmpty.singleton (ClauseIndex.MkClauseIndex 0)))}
        horde = triggered TriggerCondition.SelfEnters [mayDiscard, notDone] []
    Spec.assertEq s [[Text.pack "When Spark enters, sacrifice it unless you discard a card.", Text.pack "When Spark enters, sacrifice Spark unless you discard a card."]] (Oracle.abilities (withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [horde]})))
    let either' i c = (clause [c]) {Clause.optionality = Optionality.Optional (PlayerRef.Relative PlayerRelation.You), Clause.orElse = Just (OrElse.MkOrElse (ClauseIndex.MkClauseIndex i) (PlayerRef.Relative PlayerRelation.You) False)}
        twiddle = spell [either' 1 (Effect.Tap (ObjectRef.InSlot target)), either' 0 (Effect.Untap (ObjectRef.InSlot target))] [(target, TargetSlot.required Pool.Permanents Nothing)]
    Spec.assertEq s (Just (Text.pack "You may tap or untap target permanent.")) (Oracle.render twiddle)

  -- CR 700.2: modes as a bulleted list after the instruction to choose, each
  -- mode one line; CR 700.2d lets a mode be chosen more than once. Modes that
  -- each only add mana read as one choice of mana (Skyshroud Elf).
  Spec.it s "render prints modes as a bulleted list" $ do
    let chosen selection modes = withFace (\f -> f {Face.spell = Modal.MkModal (Seq.fromList modes) selection, Face.typeLine = TypeLine.MkTypeLine Set.empty (Set.singleton CardType.Instant) Set.empty})
        destroying t = Mode.MkMode (Seq.singleton (clause [destroy (ObjectRef.InSlot target) Regenerability.Regenerable])) (Map.singleton target (TargetSlot.required Pool.Permanents (Just (Filter.HasCardType t))))
        drawing = Mode.MkMode (Seq.singleton (clause [draw (PlayerRef.Relative PlayerRelation.You) 1])) Map.empty
    Spec.assertEq s (Just (Text.pack "Choose one \8212\n\8226 Destroy target artifact.\n\8226 Draw a card.")) (Oracle.render (chosen (ModeSelection.ChooseExactly 1) [destroying CardType.Artifact, drawing]))
    Spec.assertEq s (Just (Text.pack "Choose one or both \8212\n\8226 Destroy target artifact.\n\8226 Destroy target land.")) (Oracle.render (chosen (ModeSelection.ChooseBetween (ChooseBetween.MkChooseBetween 1 2)) [destroying CardType.Artifact, destroying CardType.Land]))
    Spec.assertEq s (Just (Text.pack "Choose three. You may choose the same mode more than once.\n\8226 Destroy target land.\n\8226 Draw a card.")) (Oracle.render (chosen (ModeSelection.ChooseExactlyWithRepeats 3) [destroying CardType.Land, drawing]))
    let three = [destroying CardType.Artifact, destroying CardType.Land, drawing]
    Spec.assertEq s (Just (Text.pack "Choose two \8212\n\8226 Destroy target artifact.\n\8226 Destroy target land.\n\8226 Draw a card.")) (Oracle.render (chosen (ModeSelection.ChooseExactly 2) three))
    Spec.assertEq s (Just (Text.pack "Choose one or more \8212\n\8226 Destroy target artifact.\n\8226 Destroy target land.\n\8226 Draw a card.")) (Oracle.render (chosen (ModeSelection.ChooseBetween (ChooseBetween.MkChooseBetween 1 3)) three))
    let adding c = Mode.MkMode (Seq.singleton (clause [Effect.AddMana (ManaAddition.MkManaAddition (PlayerRef.Relative PlayerRelation.You) (ManaProduction.OfType (ManaType.Colored c)) (Quantity.Literal 1) ManaRetention.Ordinary Nothing Nothing Nothing)])) Map.empty
        elf = ActivatedAbility.MkActivatedAbility (mana [ManaSymbol.Generic 1]) [] 0 Nothing (Modal.MkModal (Seq.fromList [adding Color.Red, adding Color.White]) (ModeSelection.ChooseExactly 1)) [] Activator.Controller Nothing Nothing Nothing
    Spec.assertEq s (Just (Text.pack "{1}: Add {R} or {W}.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [elf]})))

  -- CR 608.2c: three or more instructions read one or two at a time (Frantic
  -- Search); an object an earlier instruction named is "it" (Silvar,
  -- Devourer of the Free), a target free as "it" or "that creature"
  -- (Cryogenic Stasis, Burning Cloak), and objects a change to power and
  -- toughness reaches again get "an additional" one (Wild Might, Rhystic
  -- Shield).
  Spec.it s "render strings three instructions and names an object again" $ do
    let lands = ObjectRef.ChosenPermanents (ChosenPermanents.MkChosenPermanents (Filter.HasCardType CardType.Land) (PlayerRef.Relative PlayerRelation.You) (HowMany.UpTo (Just (Quantity.Literal 3))))
        search = spell [clause [draw (PlayerRef.Relative PlayerRelation.You) 2, discard (PlayerRef.Relative PlayerRelation.You) 2, Effect.Untap lands]] []
    Spec.assertBool s (Oracle.says search spark (Text.pack "Draw two cards, then discard two cards. Untap up to three lands.")) "Frantic Search's wording unsaid"
    let creature = [(target, TargetSlot.required Pool.Creatures Nothing)]
        stasis = spell [clause [Effect.Tap (ObjectRef.InSlot target), counters CounterKind.Stun 1 (ObjectRef.InSlot target)]] creature
    Spec.assertEq s (Just (Text.pack "Tap target creature and put a stun counter on it.")) (Oracle.render stasis)
    let cloak = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 2 0)], clause [damage [(target, 2)]]] creature
    Spec.assertEq s (Just (Text.pack "Target creature gets +2/+0 until end of turn. Spark deals 2 damage to it.")) (Oracle.render cloak)
    Spec.assertBool s (Oracle.says cloak spark (Text.pack "Target creature gets +2/+0 until end of turn. Spark deals 2 damage to that creature.")) "that creature unsaid"
    let silvar = activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) (Filter.HasSubtype Subtype.Human))]) (counters CounterKind.PlusOnePlusOne 1 (ObjectRef.InSlot self))
        indestructible = silvar {ActivatedAbility.modal = payload [clause [counters CounterKind.PlusOnePlusOne 1 (ObjectRef.InSlot self)], clause [modify (ObjectRef.InSlot self) Duration.UntilEndOfTurn (Modification.GainKeyword Keyword.Indestructible)]] []}
    Spec.assertEq s (Just (Text.pack "Sacrifice a Human: Put a +1/+1 counter on Spark. It gains indestructible until end of turn.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [indestructible]})))
    let mine = ObjectRef.EachMatching (Filter.And [Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You])
        shield = spell [clause [modify mine Duration.UntilEndOfTurn (pt 0 1)], clause [modify mine Duration.UntilEndOfTurn (pt 0 2)]] []
    Spec.assertEq s (Just (Text.pack "Creatures you control get +0/+1 until end of turn. They get an additional +0/+2 until end of turn.")) (Oracle.render shield)
    let might = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 1 1)], clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn (pt 4 4)]] creature
    Spec.assertBool s (Oracle.says might spark (Text.pack "Target creature gets +1/+1 until end of turn. That creature gets an additional +4/+4 until end of turn.")) "an additional unsaid"

  -- CR 608.2c: "If [condition], [instructions]." A spell's own condition
  -- names it, which the instructions then call "it" (Jilt); an object named
  -- already is "it" in the condition too (Sunpearl Kirin).
  Spec.it s "render prints a condition a clause waits on" $ do
    let kicked = Condition.Compares (Compares.MkCompares (Quantity.TimesPaid (KeywordDesignator.Printed KeywordFamily.Kicker)) Comparison.AtLeast (Quantity.Literal 1))
        other = SlotName.MkSlotName (Text.pack "other")
        jilt = spell [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) Zone.Hand)], (clause [damage [(other, 2)]]) {Clause.condition = Just kicked}] [(target, TargetSlot.required Pool.Creatures Nothing), (other, TargetSlot.required Pool.Creatures (Just (Filter.Not (Filter.IsBound target))))]
    Spec.assertEq s (Just (Text.pack "Return target creature to its owner's hand. If this spell was kicked, it deals 2 damage to another target creature.")) (Oracle.render jilt)
    let prowled = Condition.Compares (Compares.MkCompares (Quantity.CastUsing (KeywordDesignator.OfFamily KeywordFamily.Prowl)) Comparison.AtLeast (Quantity.Literal 1))
    Spec.assertEq s (Just (Text.pack "You gain 3 life. If this spell's prowl cost was paid, draw a card.")) (Oracle.render (spell [clause [gainLife 3], (clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.condition = Just prowled}] []))
    let wasToken = Condition.Compares (Compares.MkCompares (Quantity.AgainstSlot (AgainstSlot.MkAgainstSlot target Quantity.WasToken)) Comparison.AtLeast (Quantity.Literal 1))
        kirin = triggered TriggerCondition.SelfEnters [clause [Effect.MoveToZone (move (ObjectRef.InSlot target) Zone.Hand)], (clause [draw (PlayerRef.Relative PlayerRelation.You) 1]) {Clause.condition = Just wasToken}] [(target, upTo 1 (Just (Filter.Not Filter.IsSource)))]
    Spec.assertEq s (Just (Text.pack "When Spark enters, return up to one other target creature to its owner's hand. If it was a token, draw a card.")) (Oracle.render (withFace (\f -> (typed [CardType.Creature] [] f) {Face.triggeredAbilities = [kirin]})))

  -- CR 614.1d: a static ability's replacement effect on the source's
  -- entering; one functioning only under a condition is not spelled out.
  Spec.it s "render prints a permanent entering tapped" $ do
    let tapped = PrintedReplacement.MkPrintedReplacement Nothing (ReplacementEffect.EntryR (EntryR.MkEntryR Filter.IsSource EntryRewrite.Tapped)) Set.empty Nothing
    Spec.assertEq s (Just (Text.pack "Spark enters tapped.")) (Oracle.render (withFace (\f -> f {Face.replacementEffects = [tapped]})))
    Spec.assertEq s Nothing (Oracle.render (withFace (\f -> f {Face.replacementEffects = [tapped {PrintedReplacement.condition = Just (Condition.Compares (Compares.MkCompares (Quantity.Literal 1) Comparison.AtLeast (Quantity.Literal 1)))}]})))

  -- CR 601.2i: a cast trigger names the caster as the controller the spell's
  -- filter gives it (CR 112.2), and no controller as "a player".
  Spec.it s "render prints a trigger on casting a spell" $ do
    let cast f = withFace (\g -> g {Face.triggeredAbilities = [triggered (TriggerCondition.SpellCast (SpellCast.MkSpellCast f TurnScope.EachTurn Nothing Nothing Nothing False)) [clause [gainLife 1]] []]})
    Spec.assertEq s (Just (Text.pack "Whenever a player casts a blue spell, you gain 1 life.")) (Oracle.render (cast (Filter.HasColor Color.Blue)))
    Spec.assertEq s (Just (Text.pack "Whenever you cast an enchantment spell, you gain 1 life.")) (Oracle.render (cast (Filter.And [Filter.HasCardType CardType.Enchantment, Filter.ControlledBy PlayerRelation.You])))
    Spec.assertEq s (Just (Text.pack "Whenever an opponent casts a spell, you gain 1 life.")) (Oracle.render (cast (Filter.And [Filter.ControlledBy PlayerRelation.Opponent])))
    Spec.assertEq s (Just (Text.pack "Whenever you cast an instant or sorcery spell, you gain 1 life.")) (Oracle.render (cast (Filter.And [Filter.Or [Filter.HasCardType CardType.Instant, Filter.HasCardType CardType.Sorcery], Filter.ControlledBy PlayerRelation.You])))
    Spec.assertEq s (Just (Text.pack "Whenever you cast a Zombie spell or creature spell with flying, you gain 1 life.")) (Oracle.render (cast (Filter.And [Filter.Or [Filter.HasSubtype Subtype.Zombie, Filter.And [Filter.HasCardType CardType.Creature, Filter.HasKeyword Keyword.Flying]], Filter.ControlledBy PlayerRelation.You])))

  -- CR 701.19a: regeneration of the source, or of a target.
  Spec.it s "render prints regeneration" $ do
    let shield matching = Effect.Replace (Replace.MkReplace Duration.UntilEndOfTurn Uses.Once ReplacementOrigin.Other Nothing (ReplacementEffect.DestructionR (DestructionR.MkDestructionR matching DestructionRewrite.Regenerate)))
        regenerate matching slots = withFace (\f -> f {Face.activatedAbilities = [(activated (mana [green]) (shield matching)) {ActivatedAbility.modal = payload [clause [shield matching]] slots}]})
    Spec.assertEq s (Just (Text.pack "{G}: Regenerate Spark.")) (Oracle.render (regenerate Nothing []))
    Spec.assertEq s (Just (Text.pack "{G}: Regenerate target creature.")) (Oracle.render (regenerate (Just (Filter.IsBound target)) [(target, TargetSlot.required Pool.Creatures Nothing)]))

  -- CR 106.1 / 605.1a: a choice of mana followed by what every choice does
  -- reads as the choice and then the rest (Adarkar Wastes).
  Spec.it s "render prints a choice of mana followed by the same instructions" $ do
    let added colour = Effect.AddMana (ManaAddition.MkManaAddition (PlayerRef.Relative PlayerRelation.You) (ManaProduction.OfType (ManaType.Colored colour)) (Quantity.Literal 1) ManaRetention.Ordinary Nothing Nothing Nothing)
        mode' colour = Mode.MkMode (Seq.singleton (clause [added colour, damage [(you, 1)]])) Map.empty
        pain = (activated (Cost.MkCost (Just (ManaCost.MkManaCost [])) [CostComponent.TapThis]) (addMana 1)) {ActivatedAbility.modal = Modal.MkModal (Seq.fromList [mode' Color.White, mode' Color.Blue]) (ModeSelection.ChooseExactly 1)}
    Spec.assertEq s [[Text.pack "{T}: Add {W} or {U}. Spark deals 1 damage to you.", Text.pack "{T}: Add {W} or {U}. Then Spark deals 1 damage to you."]] (Oracle.abilities (withFace (\f -> f {Face.activatedAbilities = [pain]})))
    let uneven = pain {ActivatedAbility.modal = Modal.MkModal (Seq.fromList [mode' Color.White, Mode.MkMode (Seq.singleton (clause [added Color.Blue, damage [(you, 2)]])) Map.empty]) (ModeSelection.ChooseExactly 1)}
    Spec.assertEq s False (any (any (Text.isInfixOf (Text.pack "{W} or {U}"))) (Oracle.abilities (withFace (\f -> f {Face.activatedAbilities = [uneven]}))))

  -- CR 602.5: the clauses restricting an activation, joined by "and only".
  Spec.it s "render prints the restrictions on activating an ability" $ do
    let restricted rs = withFace (\f -> f {Face.activatedAbilities = [(activated (mana [green]) (gainLife 1)) {ActivatedAbility.restrictions = rs}]})
        upkeep = ActivationRestriction.DuringPhase (DuringPhase.MkDuringPhase (PhaseSelector.Step (Phase.Beginning BeginningStep.Upkeep)) TurnScope.ControllersTurn)
    Spec.assertEq s (Just (Text.pack "{G}: You gain 1 life. Activate only once each turn.")) (Oracle.render (restricted [ActivationRestriction.OnlyOnceEachTurn]))
    Spec.assertEq s (Just (Text.pack "{G}: You gain 1 life. Activate only as a sorcery.")) (Oracle.render (restricted [ActivationRestriction.SorcerySpeed]))
    Spec.assertEq s (Just (Text.pack "{G}: You gain 1 life. Activate only during your turn.")) (Oracle.render (restricted [ActivationRestriction.DuringTurn TurnScope.ControllersTurn]))
    Spec.assertEq s (Just (Text.pack "{G}: You gain 1 life. Activate only during your upkeep and only once each turn.")) (Oracle.render (restricted [upkeep, ActivationRestriction.OnlyOnceEachTurn]))
    Spec.assertEq s Nothing (Oracle.render (restricted [ActivationRestriction.DuringDieRoll]))

  -- CR 508.1c / 509.1b: rules permanents follow, its own or a description's;
  -- "can't attack" and "can't block" of one permanent are one ability.
  Spec.it s "render prints restrictions on attacking and blocking" $ do
    let unless' a = AffectedUnless.MkAffectedUnless a Nothing Nothing Nothing
        itself = Affected.Matching Filter.IsSource
        combat rs = withFace (\f -> f {Face.combatRestrictions = rs})
    Spec.assertEq s (Just (Text.pack "Spark can't block.")) (Oracle.render (combat [CombatRestriction.CantBlock (unless' itself)]))
    Spec.assertEq s (Just (Text.pack "Spark can't attack or block.")) (Oracle.render (combat [CombatRestriction.CantAttack (unless' itself), CombatRestriction.CantBlock (unless' itself)]))
    Spec.assertEq s (Just (Text.pack "Creatures can't block.")) (Oracle.render (combat [CombatRestriction.CantBlock (unless' (Affected.Matching (Filter.HasCardType CardType.Creature)))]))

  -- CR 701.23a: a search of your library for one card, and where it goes.
  Spec.it s "render prints a search of your library" $ do
    let search f destination = Effect.Search (Search.MkSearch (PlayerRef.Relative PlayerRelation.You) (PlayerRef.Relative PlayerRelation.You) (Set.singleton Zone.Library) False (Just (Quantity.Literal 1)) f False destination Nothing Nothing Set.empty False False)
        searching f destination = Oracle.abilities (spell [clause [search f destination]] [])
    Spec.assertEq s [[Text.pack "Search your library for a card, put that card into your hand, then shuffle."]] (searching (Filter.And []) SearchDestination.Hand)
    Spec.assertEq s [[Text.pack "Search your library for an artifact or enchantment card, reveal it, then shuffle and put that card on top.", Text.pack "Search your library for an artifact or enchantment card, reveal it, then shuffle and put the card on top."]] (searching (Filter.Or [Filter.HasCardType CardType.Artifact, Filter.HasCardType CardType.Enchantment]) SearchDestination.RevealThenTop)
    Spec.assertEq s [[Text.pack "Search your library for a basic land card, put that card onto the battlefield tapped, then shuffle.", Text.pack "Search your library for a basic land card, put it onto the battlefield tapped, then shuffle."]] (searching (Filter.And [Filter.HasSupertype Supertype.Basic, Filter.HasCardType CardType.Land]) SearchDestination.BattlefieldTapped)
    Spec.assertEq s [[Text.pack "Search your library for a blue instant card, reveal it, put it into your hand, then shuffle.", Text.pack "Search your library for a blue instant card, reveal that card, put it into your hand, then shuffle."]] (searching (Filter.And [Filter.HasColor Color.Blue, Filter.HasCardType CardType.Instant]) SearchDestination.RevealThenHand)
    Spec.assertEq s [[]] (searching (Filter.And []) SearchDestination.Stay)

  -- CR 701.17a: "Target player mills two cards."
  Spec.it s "render prints milling" $ do
    let mill = Effect.Mill (Mill.MkMill (PlayerRef.InSlot target) (Quantity.Literal 2) Nothing Nothing)
    Spec.assertEq s (Just (Text.pack "Target player mills two cards.")) (Oracle.render (spell [clause [mill]] [(target, TargetSlot.required Pool.Players Nothing)]))

  -- CR 303.4b / 301.5a: an Aura's or an Equipment's instructions name what
  -- it is attached to.
  Spec.it s "render names the host of an Aura or an Equipment" $ do
    let firebreathing subtype enchants = withFace (\f -> (typed [CardType.Enchantment] [subtype] f) {Face.enchant = enchants, Face.activatedAbilities = [activated (mana [green]) (modify (ObjectRef.EachMatching Filter.IsHostOfSource) Duration.UntilEndOfTurn (pt 1 0))]})
    Spec.assertEq s (Just (Text.pack "Enchant creature\n{G}: Enchanted creature gets +1/+0 until end of turn.")) (Oracle.render (firebreathing Subtype.Aura [TargetSlot.required Pool.Creatures Nothing]))
    Spec.assertEq s (Just (Text.pack "{G}: Equipped creature gets +1/+0 until end of turn.")) (Oracle.render (firebreathing Subtype.Equipment []))
    Spec.assertEq s Nothing (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [activated (mana [green]) (modify (ObjectRef.EachMatching Filter.IsHostOfSource) Duration.UntilEndOfTurn (pt 1 0))]})))

  -- CR 601.2f: spells of a description cost more to cast.
  Spec.it s "render prints a rule making spells cost more to cast" $ do
    let tax relation f = withFace (\g -> g {Face.playerAbilities = [PlayerStaticAbility.MkPlayerStaticAbility (PlayerScope.Related relation) Nothing Nothing (PlayerEffect.ModifyCost (CostModifier.MkCostModifier CostSubject.Spells f Nothing Nothing Nothing Nothing (CostChange.Increase (ManaCost.MkManaCost [ManaSymbol.Generic 2]))))]})
    Spec.assertEq s (Just (Text.pack "Red spells cost {2} more to cast.")) (Oracle.render (tax PlayerRelation.AnyPlayer (Filter.HasColor Color.Red)))
    Spec.assertEq s (Just (Text.pack "Noncreature spells your opponents cast cost {2} more to cast.")) (Oracle.render (tax PlayerRelation.Opponent (Filter.Not (Filter.HasCardType CardType.Creature))))
    Spec.assertEq s Nothing (Oracle.render (tax PlayerRelation.AnyPlayer (Filter.Or [Filter.HasCardType CardType.Artifact, Filter.HasCardType CardType.Enchantment])))

  -- CR 611.3a: a static ability that applies while a condition holds, the
  -- condition before or after it, and a condition on the source's own status
  -- naming it first.
  Spec.it s "render prints a static ability that applies as long as a condition holds" $ do
    let gated c changes = withFace (\f -> (typed [CardType.Creature] [] f) {Face.staticAbilities = [(static (Affected.Matching Filter.IsSource) changes) {StaticAbility.condition = Just c}]})
        atLeast q k = Condition.Compares (Compares.MkCompares q Comparison.AtLeast (Quantity.Literal k))
        forest = atLeast (countOf (Filter.And [Filter.HasSubtype Subtype.Forest, Filter.ControlledBy PlayerRelation.You]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) 1
        attacking = atLeast (countOf (Filter.And [Filter.IsSource, Filter.IsAttacking]) (onBattlefield (PlayerRef.Relative PlayerRelation.AnyPlayer))) 1
        threshold = atLeast (countOf (Filter.And []) (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You))) 7
        turn = Condition.Compares (Compares.MkCompares (Quantity.IsActivePlayer (PlayerRef.Relative PlayerRelation.You)) Comparison.Exactly (Quantity.Literal 1))
    Spec.assertEq s [[Text.pack "As long as you control a Forest, Spark gets +1/+2.", Text.pack "Spark gets +1/+2 as long as you control a Forest."]] (Oracle.abilities (gated forest [pt 1 2]))
    Spec.assertEq s [[Text.pack "As long as Spark is attacking, it has first strike.", Text.pack "Spark has first strike as long as it's attacking."]] (Oracle.abilities (gated attacking [Modification.GainKeyword Keyword.FirstStrike]))
    Spec.assertEq s [[Text.pack "As long as there are seven or more cards in your graveyard, Spark gets +1/+1.", Text.pack "Spark gets +1/+1 as long as there are seven or more cards in your graveyard.", Text.pack "Threshold \8212 As long as there are seven or more cards in your graveyard, Spark gets +1/+1.", Text.pack "Threshold \8212 Spark gets +1/+1 as long as there are seven or more cards in your graveyard."]] (Oracle.abilities (gated threshold [pt 1 1]))
    Spec.assertEq s [[Text.pack "As long as it's your turn, Spark has first strike.", Text.pack "During your turn, Spark has first strike.", Text.pack "Spark has first strike as long as it's your turn."]] (Oracle.abilities (gated turn [Modification.GainKeyword Keyword.FirstStrike]))

  -- CR 701.22a: "Scry 2."
  Spec.it s "render prints scrying" $ do
    let scry = Effect.Scry (PlayerQuantity.MkPlayerQuantity (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 2))
    Spec.assertEq s (Just (Text.pack "{G}: Scry 2.")) (Oracle.render (withFace (\f -> f {Face.activatedAbilities = [activated (mana [green]) scry]})))

  -- CR 509.1b: a creature that can't be blocked, by any creature, by
  -- creatures of a description, or except by them.
  Spec.it s "render prints a creature that can't be blocked" $ do
    let unblockable f = CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy (Affected.Matching Filter.IsSource) f Nothing Nothing)
        combat rs = withFace (\f -> f {Face.combatRestrictions = rs})
    Spec.assertEq s (Just (Text.pack "Spark can't be blocked.")) (Oracle.render (combat [unblockable (Filter.And [])]))
    Spec.assertEq s (Just (Text.pack "Spark can't be blocked by Walls.")) (Oracle.render (combat [unblockable (Filter.HasSubtype Subtype.Wall)]))
    Spec.assertEq s (Just (Text.pack "Spark can't be blocked except by Walls.")) (Oracle.render (combat [unblockable (Filter.Not (Filter.HasSubtype Subtype.Wall))]))
    Spec.assertEq s (Just (Text.pack "Spark can't block and can't be blocked.")) (Oracle.render (combat [CombatRestriction.CantBlock (AffectedUnless.MkAffectedUnless (Affected.Matching Filter.IsSource) Nothing Nothing Nothing), unblockable (Filter.And [])]))

  -- CR 509.1b: a static ability and a "can't be blocked" of the same
  -- objects are one sentence.
  Spec.it s "render reads a static ability and a can't be blocked of its objects as one" $ do
    let enchanted = Affected.Matching (Filter.And [Filter.HasCardType CardType.Creature, Filter.HasAttached Filter.IsSource])
        aura changes = withFace (\f -> (typed [CardType.Enchantment] [Subtype.Aura] f) {Face.enchant = [TargetSlot.required Pool.Creatures Nothing], Face.staticAbilities = [static enchanted changes], Face.combatRestrictions = [CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy (Affected.Matching (Filter.HasAttached Filter.IsSource)) (Filter.Not (Filter.HasKeyword Keyword.Flying)) Nothing Nothing)]})
    Spec.assertEq s (Just (Text.pack "Enchant creature\nEnchanted creature gets +1/+1 and can't be blocked except by creatures with flying.")) (Oracle.render (aura [pt 1 1]))
    Spec.assertEq s [[Text.pack "Enchant creature"], [Text.pack "Enchanted creature has shroud."], [Text.pack "Enchanted creature can't be blocked except by creatures with flying."]] (Oracle.abilities (aura [Modification.GainKeyword Keyword.Shroud]))

  -- CR 509.1b / 611.2a: a creature that can't be blocked for the rest of the
  -- turn, which Oracle text says "this turn".
  Spec.it s "render prints a creature that can't be blocked this turn" $ do
    let rules = GrantedAbility.Rules mempty {RuleAbilities.combatRestrictions = [CombatRestriction.CantBeBlockedBy (CantBeBlockedBy.MkCantBeBlockedBy (Affected.Matching Filter.IsSource) (Filter.And []) Nothing Nothing)]}
        unblocked changes = spell [clause [modify (ObjectRef.InSlot target) Duration.UntilEndOfTurn m | m <- changes]] [(target, TargetSlot.required Pool.Creatures Nothing)]
    Spec.assertEq s (Just (Text.pack "Target creature can't be blocked this turn.")) (Oracle.render (unblocked [Modification.GainAbility rules]))
    Spec.assertEq s Nothing (Oracle.render (unblocked [pt 1 0, Modification.GainAbility rules]))

  -- CR 506.7a: a time before attackers are declared follows the turn it is
  -- in after a comma.
  Spec.it s "render prints an ability activated only before attackers are declared" $ do
    let restricted rs = withFace (\f -> f {Face.activatedAbilities = [(activated (mana [green]) (gainLife 1)) {ActivatedAbility.restrictions = rs}]})
    Spec.assertEq s (Just (Text.pack "{G}: You gain 1 life. Activate only during your turn, before attackers are declared.")) (Oracle.render (restricted [ActivationRestriction.DuringTurn TurnScope.ControllersTurn, ActivationRestriction.BeforeStep (Phase.Combat CombatStep.DeclareAttackers)]))

  -- CR 207.2c: alliance and constellation, ability words Oracle text may
  -- print before an entering trigger.
  Spec.it s "render prints the ability words of entering triggers" $ do
    let entering f = withFace (\g -> (typed [CardType.Creature] [] g) {Face.triggeredAbilities = [triggered (TriggerCondition.PermanentEnters f) [clause [gainLife 1]] []]})
    Spec.assertEq s [[Text.pack "Whenever another creature you control enters, you gain 1 life.", Text.pack "Alliance \8212 Whenever another creature you control enters, you gain 1 life."]] (Oracle.abilities (entering (Filter.And [Filter.Not Filter.IsSource, Filter.HasCardType CardType.Creature, Filter.ControlledBy PlayerRelation.You])))
    Spec.assertEq s [[Text.pack "Whenever an enchantment you control enters, you gain 1 life.", Text.pack "Constellation \8212 Whenever an enchantment you control enters, you gain 1 life.", Text.pack "Whenever Spark or another enchantment you control enters, you gain 1 life.", Text.pack "Constellation \8212 Whenever Spark or another enchantment you control enters, you gain 1 life."]] (Oracle.abilities (entering (Filter.And [Filter.HasCardType CardType.Enchantment, Filter.ControlledBy PlayerRelation.You])))

-- A cost paid on resolution, offered to the payer, of which the instructions
-- are this branch.
gate :: PayBranch.PayBranch -> PlayerRef.PlayerRef -> Cost.Cost Keyword.Keyword -> PayGate.PayGate
gate branch payer cost = PayGate.MkPayGate payer (CostChoice.MkCostChoice (NonEmpty.singleton cost)) Nothing branch PayObligation.Optional Nothing Nothing

-- A cost of these mana symbols alone.
mana :: [ManaSymbol.ManaSymbol] -> Cost.Cost Keyword.Keyword
mana symbols = Cost.MkCost (Just (ManaCost.MkManaCost symbols)) []

-- A count of the members of a zone matching the filter.
countOf :: Filter.Filter Keyword.Keyword -> InZone.InZone -> Quantity.Quantity
countOf f zone = Quantity.Count (Count.MkCount (Scope.InZone zone) f Aggregation.Members)

-- The battlefield, as a count's zone.
onBattlefield :: PlayerRef.PlayerRef -> InZone.InZone
onBattlefield = InZone.MkInZone Zone.Battlefield

-- The power of the object a slot names.
powerOf :: SlotName.SlotName -> Quantity.Quantity
powerOf slot = Quantity.AgainstSlot (AgainstSlot.MkAgainstSlot slot (Quantity.Measure Measure.Power))

-- Damage of these amounts to these objects.
damageBy :: [(ObjectRef.ObjectRef, Quantity.Quantity)] -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
damageBy parts = Effect.DealDamage (DealDamage.MkDealDamage (Seq.fromList (fmap (uncurry DamagePart.MkDamagePart) parts)) Nothing Nothing Nothing)

-- You gain this much life.
gainLifeBy :: Quantity.Quantity -> Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
gainLifeBy = Effect.GainLife . PlayerQuantity.MkPlayerQuantity (PlayerRef.Relative PlayerRelation.You)

-- A change to power and toughness by these amounts.
ptBy :: Quantity.Quantity -> Quantity.Quantity -> Modification.Modification (GrantedAbility.GrantedAbility Card.Card)
ptBy p t = Modification.ModifyPowerToughness (ModifyPowerToughness.MkModifyPowerToughness p t)

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

-- The slots the engine binds a trigger event's player, the creature its
-- source blocks, and the source itself to.
thatPlayer :: SlotName.SlotName
thatPlayer = SlotName.MkSlotName (Text.pack "thatPlayer")

thatAttacker :: SlotName.SlotName
thatAttacker = SlotName.MkSlotName (Text.pack "thatAttacker")

self :: SlotName.SlotName
self = SlotName.MkSlotName (Text.pack "self")

-- The name the trigger cases' card has.
spark :: CardName.CardName
spark = CardName.MkCardName (Text.pack "Spark")

-- The instruction to sacrifice the source.
sacrifice :: Effect.Effect Card.Card (GrantedAbility.GrantedAbility Card.Card)
sacrifice = Effect.Sacrifice (SacrificeEffect.MkSacrificeEffect (ObjectRef.InSlot self) Sacrificer.EffectController Nothing)

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
damage parts = Effect.DealDamage (DealDamage.MkDealDamage (Seq.fromList (fmap (\(slot, n) -> DamagePart.MkDamagePart (ObjectRef.InSlot slot) (Quantity.Literal n)) parts)) Nothing Nothing Nothing)

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
