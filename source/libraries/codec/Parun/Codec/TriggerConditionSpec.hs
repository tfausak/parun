module Parun.Codec.TriggerConditionSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.TriggerCondition as TriggerCondition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityAddsMana as AbilityAddsMana
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.AttackCompany as AttackCompany
import qualified Parun.Types.AttackTrigger as AttackTrigger
import qualified Parun.Types.AttackerTarget as AttackerTarget
import qualified Parun.Types.AttackerTrigger as AttackerTrigger
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.BecomesTargetedTrigger as BecomesTargetedTrigger
import qualified Parun.Types.BlockCount as BlockCount
import qualified Parun.Types.BlockRole as BlockRole
import qualified Parun.Types.BlockTrigger as BlockTrigger
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CausedBy as CausedBy
import qualified Parun.Types.ClassLevel as ClassLevel
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.Types.CounterGrouping as CounterGrouping
import qualified Parun.Types.CounterHolder as CounterHolder
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterMotion as CounterMotion
import qualified Parun.Types.CounterTrigger as CounterTrigger
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamageRecipient as DamageRecipient
import qualified Parun.Types.DamageTrigger as DamageTrigger
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.DieResult as DieResult
import qualified Parun.Types.DiscardSubject as DiscardSubject
import qualified Parun.Types.DiscardTrigger as DiscardTrigger
import qualified Parun.Types.DiscardWay as DiscardWay
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.EntersTrigger as EntersTrigger
import qualified Parun.Types.ExploitTrigger as ExploitTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.LeavesTrigger as LeavesTrigger
import qualified Parun.Types.LeavesZoneTrigger as LeavesZoneTrigger
import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentAction as PermanentAction
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Types.PermanentIsDealtDamage as PermanentIsDealtDamage
import qualified Parun.Types.PermanentTappedForMana as PermanentTappedForMana
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlacesSticker as PlacesSticker
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import qualified Parun.Types.PlayerActsOn as PlayerActsOn
import qualified Parun.Types.PlayerDrawsNthCard as PlayerDrawsNthCard
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlaysLand as PlaysLand
import qualified Parun.Types.PutIntoZoneTrigger as PutIntoZoneTrigger
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RevealedThisWay as RevealedThisWay
import qualified Parun.Types.RoomIndex as RoomIndex
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.StickerKind as StickerKind
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TransformTrigger as TransformTrigger
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | At least one case per TriggerCondition constructor. RoomFullyUnlocked gets
-- two, one per PlayerRelation, since CR 109.5's "you" against "an opponent" is
-- the whole of that payload.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TriggerCondition" $ do
  -- CR 603.6a; Parun.Codec.EntersTriggerSpec has the fields.
  Spec.it s "Enters" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Enters EntersTrigger.defaultValue)
      " {\"type\":\"Enters\",\"value\":{}} "
  -- CR 603.2b.
  Spec.it s "StepBegins round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.StepBegins (StepBegins.MkStepBegins (Phase.Ending EndingStep.EndStep) Nothing TurnScope.EachTurn))
      " {\"type\":\"StepBegins\",\"value\":{\"phase\":{\"type\":\"Ending\",\"value\":{\"type\":\"EndStep\"}},\"scope\":{\"type\":\"EachTurn\"}}} "
  -- CR 603.8: a STATE trigger, carrying its Condition.
  Spec.it s "StateIs round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.StateIs (Condition.Compares (Compares.MkCompares (Quantity.Literal 0) Comparison.Exactly (Quantity.Literal 0))))
      " {\"type\":\"StateIs\",\"value\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":0},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}} "
  -- CR 603.2 / 120.1: the damage trigger, its record's own spec covering the
  -- fields (Parun.Codec.DamageTriggerSpec).
  Spec.it s "DealsDamage" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DealsDamage (DamageTrigger.MkDamageTrigger ActingPermanent.Self (Just DamageKind.Combat) (Set.singleton (DamageRecipient.Player PlayerRelation.Opponent))))
      " {\"type\":\"DealsDamage\",\"value\":{\"actor\":{\"type\":\"Self\"},\"kind\":{\"type\":\"Combat\"},\"recipients\":[{\"type\":\"Player\",\"value\":{\"type\":\"Opponent\"}}]}} "
  -- CR 120.3: the same history read the other way round -- the permanent was
  -- DEALT damage.
  Spec.it s "IsDealtDamage round-trips both actors and a kind" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.IsDealtDamage (PermanentIsDealtDamage.MkPermanentIsDealtDamage (DealtDamage.MkDealtDamage ActingPermanent.Self Nothing) Batching.OneOrMore))
      " {\"type\":\"IsDealtDamage\",\"value\":{\"dealt\":{\"recipient\":{\"type\":\"Self\"}}}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.IsDealtDamage (PermanentIsDealtDamage.MkPermanentIsDealtDamage (DealtDamage.MkDealtDamage (ActingPermanent.Matching (Filter.HasCardType CardType.Creature)) Nothing) Batching.OneOrMore))
      " {\"type\":\"IsDealtDamage\",\"value\":{\"dealt\":{\"recipient\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}}}} "
    -- Wall of Essence's "is dealt combat damage".
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.IsDealtDamage (PermanentIsDealtDamage.MkPermanentIsDealtDamage (DealtDamage.MkDealtDamage ActingPermanent.Self (Just DamageKind.Combat)) Batching.OneOrMore))
      " {\"type\":\"IsDealtDamage\",\"value\":{\"dealt\":{\"recipient\":{\"type\":\"Self\"},\"kind\":{\"type\":\"Combat\"}}}} "
  -- Lich's any damage, and Chandra's Spitfire's noncombat damage to an
  -- opponent.
  Spec.it s "PlayerIsDealtDamage round-trips both kinds" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerIsDealtDamage (PlayerIsDealtDamage.MkPlayerIsDealtDamage (DealtDamage.MkDealtDamage PlayerRelation.You Nothing) False))
      " {\"type\":\"PlayerIsDealtDamage\",\"value\":{\"dealt\":{\"recipient\":{\"type\":\"You\"}}}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerIsDealtDamage (PlayerIsDealtDamage.MkPlayerIsDealtDamage (DealtDamage.MkDealtDamage PlayerRelation.Opponent (Just DamageKind.Noncombat)) False))
      " {\"type\":\"PlayerIsDealtDamage\",\"value\":{\"dealt\":{\"recipient\":{\"type\":\"Opponent\"},\"kind\":{\"type\":\"Noncombat\"}}}} "
  -- CR 603.2c's batch reading of DealsDamage's combat damage to a player, so a
  -- separate tag is the only thing that keeps Pia Nalaar's once-per-step card and
  -- Tovolar's once-per-damager card apart on the wire.
  Spec.it s "PermanentsDealCombatDamageToPlayer round-trips with its Filter and recipient" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentsDealCombatDamageToPlayer (PermanentsDealCombatDamageToPlayer.MkPermanentsDealCombatDamageToPlayer (Filter.And [Filter.HasCardType CardType.Artifact, Filter.HeldBy Holder.Controller PlayerRelation.You]) PlayerRelation.AnyPlayer False))
      " {\"type\":\"PermanentsDealCombatDamageToPlayer\",\"value\":{\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]},\"recipient\":{\"type\":\"AnyPlayer\"}}} "
  -- CR 725.2: a creature dealt combat damage to the monarch.
  Spec.it s "CreatureDealtCombatDamageToMonarch" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.CreatureDealtCombatDamageToMonarch
      " {\"type\":\"CreatureDealtCombatDamageToMonarch\"} "
  -- CR 726.2: one or more creatures dealt combat damage to the player who has the
  -- initiative, and a player took the initiative.
  Spec.it s "CreaturesDealtCombatDamageToInitiative" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.CreaturesDealtCombatDamageToInitiative
      " {\"type\":\"CreaturesDealtCombatDamageToInitiative\"} "
  Spec.it s "PlayerTookInitiative" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.PlayerTookInitiative
      " {\"type\":\"PlayerTookInitiative\"} "
  -- CR 702.29c's "when you cycle this card"; the payload's own cases are
  -- Parun.Codec.DiscardTriggerSpec's.
  Spec.it s "Discards" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Discards (DiscardTrigger.MkDiscardTrigger DiscardSubject.Self DiscardWay.Cycled Batching.EachOccurrence))
      " {\"type\":\"Discards\",\"value\":{\"subject\":{\"type\":\"Self\"},\"way\":{\"type\":\"Cycled\"}}} "
  -- CR 702.94a's linked half.
  Spec.it s "SelfRevealedForMiracle" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfRevealedForMiracle
      " {\"type\":\"SelfRevealedForMiracle\"} "
  -- CR 607.2h's linked half: Rowen's.
  Spec.it s "RevealedThisWay" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.RevealedThisWay (RevealedThisWay.MkRevealedThisWay (Filter.HasCardType CardType.Land) Nothing))
      " {\"type\":\"RevealedThisWay\",\"value\":{\"card\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}} "
  -- CR 121.1's Nth draw of a turn. The relation and the ordinal are both content,
  -- and the ordinal is not 1, so a codec dropping it would fail rather than
  -- round-trip the default.
  Spec.it s "PlayerDrawsNthCard" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerDrawsNthCard (PlayerDrawsNthCard.MkPlayerDrawsNthCard PlayerRelation.You (Just 2)))
      " {\"type\":\"PlayerDrawsNthCard\",\"value\":{\"player\":{\"type\":\"You\"},\"nth\":2}} "
  -- CR 508.3a: the source's own "whenever this creature attacks", whose
  -- fields all default. Parun.Codec.AttackTriggerSpec has the other arms.
  Spec.it s "Attacks" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Attacks (AttackTrigger.Attacker (AttackerTrigger.MkAttackerTrigger Filter.IsSource AttackerTarget.AnyTarget AttackCompany.AnyCompany TriggerFrequency.EveryTime Nothing)))
      " {\"type\":\"Attacks\",\"value\":{\"type\":\"Attacker\",\"value\":{}}} "
  -- CR 509.3e read by a bystander: Seifer, Balamb Rival's "a creature attacking
  -- one of your opponents becomes blocked by two or more creatures".
  Spec.it s "Blocks" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Blocks (BlockTrigger.MkBlockTrigger BlockRole.Attacker (Filter.IsAttackingPlayer PlayerRelation.Opponent) (BlockCount.AtLeast 2 (Filter.And []))))
      " {\"type\":\"Blocks\",\"value\":{\"role\":{\"type\":\"Attacker\"},\"creature\":{\"type\":\"IsAttackingPlayer\",\"value\":{\"type\":\"Opponent\"}},\"count\":{\"type\":\"AtLeast\",\"value\":{\"floor\":2}}}} "
  Spec.it s "Leaves" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Leaves LeavesTrigger.defaultValue)
      " {\"type\":\"Leaves\",\"value\":{}} "
  Spec.it s "LeavesZone" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.LeavesZone (LeavesZoneTrigger.self Zone.Graveyard))
      " {\"type\":\"LeavesZone\",\"value\":{\"from\":{\"type\":\"Graveyard\"}}} "
  Spec.it s "PutIntoZone" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PutIntoZone (PutIntoZoneTrigger.self Zone.Graveyard))
      " {\"type\":\"PutIntoZone\",\"value\":{\"to\":{\"type\":\"Graveyard\"}}} "
  -- CR 701.26a's tap, once per permanent, read off the bearer by id.
  Spec.it s "BecomesTapState round-trips the bearer itself" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BecomesTapState (BecomesTapState.MkBecomesTapState TapState.Tapped ActingPermanent.Self))
      " {\"type\":\"BecomesTapState\",\"value\":{\"actor\":{\"type\":\"Self\"},\"status\":{\"type\":\"Tapped\"}}} "
  -- CR 701.26b's untap of a permanent the Filter admits.
  Spec.it s "BecomesTapState round-trips a Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BecomesTapState (BecomesTapState.MkBecomesTapState TapState.Untapped (ActingPermanent.Matching (Filter.HasSubtype Subtype.Island))))
      " {\"type\":\"BecomesTapState\",\"value\":{\"actor\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Island\"}}},\"status\":{\"type\":\"Untapped\"}}} "
  -- CR 701.26a's tap by a bystander, batch-read (CR 603.2c).
  Spec.it s "PermanentsBecomeTapped round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentsBecomeTapped (Filter.Not Filter.IsToken))
      " {\"type\":\"PermanentsBecomeTapped\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}}} "
  -- CR 106.12a's tap for mana read off the attachment link. Nullary: that link is
  -- board state, so nothing about it rides the condition.
  Spec.it s "AttachedPermanentTappedForMana" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.AttachedPermanentTappedForMana
      " {\"type\":\"AttachedPermanentTappedForMana\"} "
  -- CR 605.1b's other alternative, self-scoped and so carrying nothing:
  -- Tyvar the Bellicose's granted "whenever a mana ability of this creature
  -- resolves".
  Spec.it s "SelfManaAbilityResolves" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfManaAbilityResolves
      " {\"type\":\"SelfManaAbilityResolves\"} "
  -- The same event read by a bystander, so every part of the printed sentence
  -- rides the condition -- Autumn Willow, Harmony's "whenever YOU tap a LAND
  -- CREATURE for mana", which narrows the mana not at all.
  Spec.it s "PermanentTappedForMana round-trips every half" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentTappedForMana (PermanentTappedForMana.MkPermanentTappedForMana PlayerRelation.You (Filter.HasCardType CardType.Land) ManaSpecification.AnyMana))
      " {\"type\":\"PermanentTappedForMana\",\"value\":{\"player\":{\"type\":\"You\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"mana\":{\"type\":\"AnyMana\"}}} "
  -- CR 605.1b's mana-added watch, Caged Sun's: you, a land's ability, the
  -- chosen color.
  Spec.it s "AbilityAddsMana round-trips every half" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.AbilityAddsMana (AbilityAddsMana.MkAbilityAddsMana PlayerRelation.You (Filter.HasCardType CardType.Land) ManaSpecification.ChosenColor))
      " {\"type\":\"AbilityAddsMana\",\"value\":{\"player\":{\"type\":\"You\"},\"source\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"mana\":{\"type\":\"ChosenColor\"}}} "
  -- CR 701.6a's countering. Both relations: each is content.
  Spec.it s "SpellOrAbilityCounters round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellOrAbilityCounters PlayerRelation.You)
      " {\"type\":\"SpellOrAbilityCounters\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellOrAbilityCounters PlayerRelation.Opponent)
      " {\"type\":\"SpellOrAbilityCounters\",\"value\":{\"type\":\"Opponent\"}} "
  -- The same rule read from the victim's side, and nullary: the printed sentence
  -- names no player, so there is no relation to round-trip.
  Spec.it s "AbilityIsCountered" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.AbilityIsCountered
      " {\"type\":\"AbilityIsCountered\"} "
  -- CR 615.13's prevention trigger. Both relations, for the same reason.
  Spec.it s "DamageToPlayerPrevented round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DamageToPlayerPrevented PlayerRelation.You)
      " {\"type\":\"DamageToPlayerPrevented\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DamageToPlayerPrevented PlayerRelation.Opponent)
      " {\"type\":\"DamageToPlayerPrevented\",\"value\":{\"type\":\"Opponent\"}} "
  -- Rule 615.13's other reading, "prevented this way". No relation -- its subject
  -- is the bearer's own prevention effect -- but a Filter over the damage's
  -- source, which Samite Ministration's "black or red" carries and Phyrexian
  -- Vindicator leaves trivial.
  Spec.it s "SelfPreventsDamage round-trips with its Filter" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfPreventsDamage (Filter.And []))
      " {\"type\":\"SelfPreventsDamage\",\"value\":{\"type\":\"And\",\"value\":[]}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfPreventsDamage (Filter.Or [Filter.HasColor Color.Black, Filter.HasColor Color.Red]))
      " {\"type\":\"SelfPreventsDamage\",\"value\":{\"type\":\"Or\",\"value\":[{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}},{\"type\":\"HasColor\",\"value\":{\"type\":\"Red\"}}]}} "
  -- CR 119.9's life-gain trigger, every defaulted key elided.
  Spec.it s "LifeChanges round-trips a bare gain" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.LifeChanges (LifeTrigger.MkLifeTrigger LifeDirection.Gained PlayerRelation.You TurnScope.EachTurn Batching.EachOccurrence TriggerFrequency.EveryTime))
      " {\"type\":\"LifeChanges\",\"value\":{\"direction\":{\"type\":\"Gained\"},\"player\":{\"type\":\"You\"}}} "
  -- Vengeful Warchief.
  Spec.it s "LifeChanges carries a frequency" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.LifeChanges (LifeTrigger.MkLifeTrigger LifeDirection.Lost PlayerRelation.You TurnScope.EachTurn Batching.EachOccurrence TriggerFrequency.FirstTimeEachTurn))
      " {\"type\":\"LifeChanges\",\"value\":{\"direction\":{\"type\":\"Lost\"},\"player\":{\"type\":\"You\"},\"frequency\":{\"type\":\"FirstTimeEachTurn\"}}} "
  -- CR 702.179d's speed trigger: a batch, on the controller's turn.
  Spec.it s "LifeChanges carries a scope and a batching" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.LifeChanges (LifeTrigger.MkLifeTrigger LifeDirection.Lost PlayerRelation.Opponent TurnScope.ControllersTurn Batching.OneOrMore TriggerFrequency.EveryTime))
      " {\"type\":\"LifeChanges\",\"value\":{\"direction\":{\"type\":\"Lost\"},\"player\":{\"type\":\"Opponent\"},\"scope\":{\"type\":\"ControllersTurn\"},\"batching\":{\"type\":\"OneOrMore\"}}} "
  -- CR 714.2b's chapter III; Parun.Codec.CounterTriggerSpec covers the
  -- payload's other keys.
  Spec.it s "CountersChange round-trips its payload" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CountersChange (CounterTrigger.MkCounterTrigger CounterKind.Lore (CounterMotion.Put PlayerRelation.AnyPlayer) CounterHolder.Self (Just 3) CounterGrouping.EachPermanent))
      " {\"type\":\"CountersChange\",\"value\":{\"kind\":{\"type\":\"Lore\"},\"motion\":{\"type\":\"Put\",\"value\":{\"type\":\"AnyPlayer\"}},\"threshold\":3}} "
  -- CR 716.2a. The payload is the bar's printed level number and nothing else:
  -- the ability is printed on the Class whose level changes, so there is nothing
  -- to select among.
  Spec.it s "SelfBecomesClassLevel round-trips its level" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesClassLevel (ClassLevel.MkClassLevel 2))
      " {\"type\":\"SelfBecomesClassLevel\",\"value\":2} "
  -- CR 601.2i. A PAIR: a Filter over the SPELL, holding Young Pyromancer's two
  -- printed narrowings -- who cast it and what it was -- plus the TurnScope,
  -- which is the axis the Filter cannot carry. Young Pyromancer prints no turn,
  -- so EachTurn is its half.
  Spec.it s "SpellCast round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellCast (SpellCast.MkSpellCast (ActingPermanent.Matching (Filter.And [Filter.HeldBy Holder.Controller PlayerRelation.You, Filter.Or [Filter.HasCardType CardType.Instant, Filter.HasCardType CardType.Sorcery]])) TurnScope.EachTurn Nothing Nothing Nothing False))
      " {\"type\":\"SpellCast\",\"value\":{\"spell\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},{\"type\":\"Or\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}},{\"type\":\"HasCardType\",\"value\":{\"type\":\"Sorcery\"}}]}]}},\"scope\":{\"type\":\"EachTurn\"}}} "
  -- The other half moved on its own, over the plainest Filter there is: Brineborn
  -- Cutthroat's "during an opponent's turn", which no Filter could have said.
  Spec.it s "SpellCast round-trips an opponent's-turn scope" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellCast (SpellCast.MkSpellCast (ActingPermanent.Matching (Filter.HeldBy Holder.Controller PlayerRelation.You)) TurnScope.OpponentsTurn Nothing Nothing Nothing False))
      " {\"type\":\"SpellCast\",\"value\":{\"spell\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}},\"scope\":{\"type\":\"OpponentsTurn\"}}} "
  -- CR 702.21a's ward: a Self subject, the relation on the TARGETING side.
  -- Parun.Codec.BecomesTargetedTriggerSpec has the fields.
  Spec.it s "BecomesTargeted round-trips ward's opponent relation" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BecomesTargeted BecomesTargetedTrigger.defaultValue {BecomesTargetedTrigger.relation = PlayerRelation.Opponent})
      " {\"type\":\"BecomesTargeted\",\"value\":{\"relation\":{\"type\":\"Opponent\"}}} "
  -- The same rule from the PLAYER's side. Two cases, because the payload's kind
  -- is elided when absent: Amulet of Safekeeping's "a spell or ability an
  -- opponent controls" writes no kind, and Dormant Gomazoa's "a spell" writes
  -- one.
  Spec.it s "ControllerBecomesTarget, a spell or ability alike" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.ControllerBecomesTarget (ControllerBecomesTarget.MkControllerBecomesTarget {ControllerBecomesTarget.relation = PlayerRelation.Opponent, ControllerBecomesTarget.kind = Nothing}))
      " {\"type\":\"ControllerBecomesTarget\",\"value\":{\"relation\":{\"type\":\"Opponent\"}}} "
  Spec.it s "ControllerBecomesTarget, a spell only" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.ControllerBecomesTarget (ControllerBecomesTarget.MkControllerBecomesTarget {ControllerBecomesTarget.relation = PlayerRelation.AnyPlayer, ControllerBecomesTarget.kind = Just StackObjectKind.Spell}))
      " {\"type\":\"ControllerBecomesTarget\",\"value\":{\"relation\":{\"type\":\"AnyPlayer\"},\"kind\":{\"type\":\"Spell\"}}} "
  -- CR 603.2c's batch reading with a Filter over the targeted permanents:
  -- Professor Hojo's.
  Spec.it s "BecomesTargeted round-trips a batch over a Matching subject and its kind" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BecomesTargeted (BecomesTargetedTrigger.matching (Filter.HeldBy Holder.Controller PlayerRelation.You)) {BecomesTargetedTrigger.kind = Just StackObjectKind.ActivatedAbility, BecomesTargetedTrigger.batching = Batching.OneOrMore})
      " {\"type\":\"BecomesTargeted\",\"value\":{\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}},\"kind\":{\"type\":\"ActivatedAbility\"},\"batching\":{\"type\":\"OneOrMore\"}}} "
  -- Venerated Rotpriest's per-permanent reading, an opponent's spell.
  Spec.it s "BecomesTargeted round-trips a Matching subject per permanent" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BecomesTargeted (BecomesTargetedTrigger.matching (Filter.HeldBy Holder.Controller PlayerRelation.You)) {BecomesTargetedTrigger.relation = PlayerRelation.Opponent, BecomesTargetedTrigger.kind = Just StackObjectKind.Spell})
      " {\"type\":\"BecomesTargeted\",\"value\":{\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}},\"relation\":{\"type\":\"Opponent\"},\"kind\":{\"type\":\"Spell\"}}} "
  -- CR 601.2i read off the spell itself, Desolation Twin's "when you cast this
  -- spell": a Self subject, every other field at SpellCast.self's value.
  Spec.it s "SpellCast round-trips a Self subject" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellCast SpellCast.self)
      " {\"type\":\"SpellCast\",\"value\":{\"spell\":{\"type\":\"Self\"},\"scope\":{\"type\":\"EachTurn\"}}} "
  Spec.it s "AbilityActivated round-trips its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.AbilityActivated (Filter.HeldBy Holder.Controller PlayerRelation.You))
      " {\"type\":\"AbilityActivated\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}} "
  -- CR 709.5h. The payload is the DOOR's own name (CR 709.4a), which is what
  -- separates two unlock triggers printed on one Room.
  Spec.it s "SelfHalfUnlocked round-trips its door" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfHalfUnlocked (CardName.MkCardName (Text.pack "Steaming Sauna")))
      " {\"type\":\"SelfHalfUnlocked\",\"value\":\"Steaming Sauna\"} "
  -- CR 701.27e: Blightreaper Thallid's Self subject and the face it names.
  -- Parun.Codec.TransformTriggerSpec has the fields.
  Spec.it s "Transforms round-trips the face a Self subject names" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Transforms TransformTrigger.defaultValue {TransformTrigger.into = Just (CardName.MkCardName (Text.pack "Blightsower Thallid"))})
      " {\"type\":\"Transforms\",\"value\":{\"into\":\"Blightsower Thallid\"}} "
  -- The same rule read by a bystander, Cult of the Waxing Moon's Filter.
  Spec.it s "Transforms round-trips a Matching subject" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Transforms TransformTrigger.defaultValue {TransformTrigger.permanent = ActingPermanent.Matching (Filter.Not (Filter.HasSubtype Subtype.Human))})
      " {\"type\":\"Transforms\",\"value\":{\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Human\"}}}}}} "
  -- CR 709.5i. The payload is a PlayerRelation, read against the player who
  -- unlocked the permanent. BOTH relations, since the two are what
  -- separate "you fully unlock" from an opponent doing it.
  Spec.it s "RoomFullyUnlocked round-trips its relation" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.RoomFullyUnlocked PlayerRelation.You)
      " {\"type\":\"RoomFullyUnlocked\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "RoomFullyUnlocked round-trips the opponent relation too" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.RoomFullyUnlocked PlayerRelation.Opponent)
      " {\"type\":\"RoomFullyUnlocked\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 603.1b's "more than one trigger condition": one ability, two clauses. The
  -- only RECURSIVE condition, so both directions of the codec call themselves.
  --
  -- Balemurk Leech's own pair, which is neither empty nor a singleton on purpose:
  -- a codec that kept only the first branch, or that dropped the list entirely,
  -- would round-trip a one-element list unchanged and pass.
  -- CR 609.1's narrowing, which holds the condition it narrows.
  Spec.it s "CausedBy round-trips its relation and its condition" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CausedBy CausedBy.MkCausedBy {CausedBy.controller = PlayerRelation.Opponent, CausedBy.condition = TriggerCondition.Discards (DiscardTrigger.MkDiscardTrigger (DiscardSubject.Discarder (PlayerActsOn.MkPlayerActsOn PlayerRelation.You (Filter.And []))) DiscardWay.AnyDiscard Batching.EachOccurrence)})
      " {\"type\":\"CausedBy\",\"value\":{\"controller\":{\"type\":\"Opponent\"},\"condition\":{\"type\":\"Discards\",\"value\":{\"subject\":{\"type\":\"Discarder\",\"value\":{\"player\":{\"type\":\"You\"},\"filter\":{\"type\":\"And\",\"value\":[]}}}}}}} "
  Spec.it s "AnyOf round-trips both of its branches" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.AnyOf [TriggerCondition.Enters (EntersTrigger.matching (Filter.HasCardType CardType.Enchantment)), TriggerCondition.RoomFullyUnlocked PlayerRelation.You])
      " {\"type\":\"AnyOf\",\"value\":[{\"type\":\"Enters\",\"value\":{\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Enchantment\"}}}}},{\"type\":\"RoomFullyUnlocked\",\"value\":{\"type\":\"You\"}}]} "
  -- CR 708.7 through CR 603.2: Skirk Marauder's "this creature", the bearer.
  Spec.it s "TurnedFaceUp round-trips a Self subject" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.TurnedFaceUp ActingPermanent.Self)
      " {\"type\":\"TurnedFaceUp\",\"value\":{\"type\":\"Self\"}} "
  -- Aven Farseer's "a permanent", the trivial Filter.
  Spec.it s "TurnedFaceUp round-trips a Matching subject with the trivial Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.TurnedFaceUp (ActingPermanent.Matching (Filter.And [])))
      " {\"type\":\"TurnedFaceUp\",\"value\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[]}}} "
  -- Deathmist Raptor's "a permanent you control": the Filter survives the trip.
  Spec.it s "TurnedFaceUp round-trips a Matching subject with a narrowing Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.TurnedFaceUp (ActingPermanent.Matching (Filter.HeldBy Holder.Controller PlayerRelation.You)))
      " {\"type\":\"TurnedFaceUp\",\"value\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}}} "
  -- CR 603.2: both fields ride on the wire. Renegade Krasis' self-scoped
  -- "whenever this creature evolves", and Wildgrowth Walker's bystander "whenever
  -- a creature you control explores", whose Filter must survive the trip.
  Spec.it s "PermanentActs round-trips the action and the subject" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentActs (PermanentActed.MkPermanentActed PermanentAction.Evolve ActingPermanent.Self))
      " {\"type\":\"PermanentActs\",\"value\":{\"action\":{\"type\":\"Evolve\"},\"permanent\":{\"type\":\"Self\"}}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentActs (PermanentActed.MkPermanentActed PermanentAction.Explore (ActingPermanent.Matching (Filter.HeldBy Holder.Controller PlayerRelation.You))))
      " {\"type\":\"PermanentActs\",\"value\":{\"action\":{\"type\":\"Explore\"},\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}}}} "
  -- CR 708.9: Synthetic Unmasking Witness's condition.
  Spec.it s "FaceDownPermanentLeavesRevealed round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.FaceDownPermanentLeavesRevealed
      " {\"type\":\"FaceDownPermanentLeavesRevealed\"} "
  -- CR 702.112b's designation, carrying Valeron Wardens' own narrowing: the pair of
  -- designation and Filter is the whole payload, so both have to survive both
  -- directions -- a dropped designation would make this condition match Arbor
  -- Colossus' monstrous event too.
  Spec.it s "PermanentBecomesDesignated round-trips with its designation and Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentBecomesDesignated (PermanentBecomesDesignated.MkPermanentBecomesDesignated Designation.Renowned (Filter.HeldBy Holder.Controller PlayerRelation.You)))
      " {\"type\":\"PermanentBecomesDesignated\",\"value\":{\"designation\":{\"type\":\"Renowned\"},\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}}} "
  -- CR 701.37b through the same constructor: Arbor Colossus' "when this creature
  -- becomes monstrous", which is Filter.IsSource beside the other designation.
  Spec.it s "PermanentBecomesDesignated carries Monstrous" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentBecomesDesignated (PermanentBecomesDesignated.MkPermanentBecomesDesignated Designation.Monstrous Filter.IsSource))
      " {\"type\":\"PermanentBecomesDesignated\",\"value\":{\"designation\":{\"type\":\"Monstrous\"},\"filter\":{\"type\":\"IsSource\"}}} "
  -- CR 702.134c's marker, read through the source's attachment, so nullary:
  -- neither the mentor nor the mentored creature is named by the condition.
  Spec.it s "AttachedCreatureMentors" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.AttachedCreatureMentors
      " {\"type\":\"AttachedCreatureMentors\"} "
  -- CR 702.110b; Parun.Codec.ExploitTriggerSpec has the fields.
  Spec.it s "Exploits" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.Exploits ExploitTrigger.defaultValue)
      " {\"type\":\"Exploits\",\"value\":{}} "
  -- CR 702.122e's marker, self-scoped but carrying a frequency -- Mighty Servant of Leuk-o prints "for the first time each
  -- turn". Both, since either could round-trip alone.
  Spec.it s "SelfBecomesCrewed round-trips both frequencies" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesCrewed TriggerFrequency.EveryTime)
      " {\"type\":\"SelfBecomesCrewed\",\"value\":{\"type\":\"EveryTime\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesCrewed TriggerFrequency.FirstTimeEachTurn)
      " {\"type\":\"SelfBecomesCrewed\",\"value\":{\"type\":\"FirstTimeEachTurn\"}} "
  -- CR 702.122b's crewer side, nullary: self-scoped; the arm
  -- before it is where a frequency would go if a card printed one.
  Spec.it s "SelfCrewsVehicle" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfCrewsVehicle
      " {\"type\":\"SelfCrewsVehicle\"} "
  -- CR 603.10a's sacrifice family, narrowed both ways: Vengeful Tracker's
  -- "whenever an opponent sacrifices an artifact".
  Spec.it s "PermanentSacrificed round-trips both halves" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentSacrificed (PlayerActsOn.MkPlayerActsOn PlayerRelation.Opponent (Filter.HasCardType CardType.Artifact)))
      " {\"type\":\"PermanentSacrificed\",\"value\":{\"player\":{\"type\":\"Opponent\"},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}}}} "
  -- CR 603.3b's second class. The relation is the only payload: which Saga and
  -- which chapter are read off the event and the source's projection.
  Spec.it s "SagaFinalChapterTriggers round-trips its relation" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SagaFinalChapterTriggers PlayerRelation.You)
      " {\"type\":\"SagaFinalChapterTriggers\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "SagaFinalChapterTriggers round-trips the opponent relation too" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SagaFinalChapterTriggers PlayerRelation.Opponent)
      " {\"type\":\"SagaFinalChapterTriggers\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 725.1's crowning. Both relations, since the PlayerRelation is the whole
  -- payload and the whole difference between "whenever you become the monarch"
  -- and "whenever an opponent becomes the monarch", so a codec that dropped it
  -- would silently turn one printing into the other.
  Spec.it s "PlayerBecomesMonarch round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerBecomesMonarch PlayerRelation.You)
      " {\"type\":\"PlayerBecomesMonarch\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerBecomesMonarch PlayerRelation.Opponent)
      " {\"type\":\"PlayerBecomesMonarch\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 603.7's slot-named condition. The slot is a bare string, as every other
  -- SlotName in card data is, and it is the whole payload: a codec that dropped it
  -- would leave the condition asking about no creature at all.
  Spec.it s "LoseControlOfBound round-trips its slot" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.LoseControlOfBound (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"LoseControlOfBound\",\"value\":\"target\"} "
  -- CR 603.10d's self-scoped twin, a bare tag.
  Spec.it s "LoseControlOfSelf round-trips" $
    Common.assertCodec s TriggerCondition.codec TriggerCondition.LoseControlOfSelf " {\"type\":\"LoseControlOfSelf\"} "
  -- CR 309.4c. No dungeon card prints this condition -- Parun.Engine.Dungeon mints
  -- one per room -- but it round-trips like every other arm.
  Spec.it s "RoomEntered round-trips its room" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.RoomEntered (RoomIndex.MkRoomIndex 3))
      " {\"type\":\"RoomEntered\",\"value\":3} "
  -- CR 603.2: both fields ride on the wire, so a codec that dropped the action
  -- would fold Matoya, Archon Elder's AnyOf of a scry and a surveil into one
  -- condition that fires twice on a scry. Two relations, for
  -- PlayerBecomesMonarch's reason.
  Spec.it s "PlayerActs round-trips the action and the relation" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerActs (PlayerActed.MkPlayerActed PlayerAction.Scry PlayerRelation.You))
      " {\"type\":\"PlayerActs\",\"value\":{\"action\":{\"type\":\"Scry\"},\"player\":{\"type\":\"You\"}}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerActs (PlayerActed.MkPlayerActed PlayerAction.Firebend PlayerRelation.AnyPlayer))
      " {\"type\":\"PlayerActs\",\"value\":{\"action\":{\"type\":\"Firebend\"},\"player\":{\"type\":\"AnyPlayer\"}}} "
  -- CR 305.1: Urianger Augurelt's "whenever you play a land from exile".
  Spec.it s "PlayerPlaysLand" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerPlaysLand (PlaysLand.MkPlaysLand PlayerRelation.You Zone.Exile (Filter.And [])))
      " {\"type\":\"PlayerPlaysLand\",\"value\":{\"player\":{\"type\":\"You\"},\"from\":{\"type\":\"Exile\"},\"filter\":{\"type\":\"And\",\"value\":[]}}} "
  -- CR 603.9. Withengar Unbound's "a player" and Share the Spoils' "an
  -- opponent".
  Spec.it s "PlayerLosesGame round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerLosesGame PlayerRelation.AnyPlayer)
      " {\"type\":\"PlayerLosesGame\",\"value\":{\"type\":\"AnyPlayer\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerLosesGame PlayerRelation.Opponent)
      " {\"type\":\"PlayerLosesGame\",\"value\":{\"type\":\"Opponent\"}} "
  Spec.it s "PlayerManifestsDread" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerManifestsDread PlayerRelation.You)
      " {\"type\":\"PlayerManifestsDread\",\"value\":{\"type\":\"You\"}} "
  -- CR 706.2: Night Shift of the Living Dead's "whenever you roll a 6".
  Spec.it s "PlayerRollsResult" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerRollsResult DieResult.MkDieResult {DieResult.roller = PlayerRelation.You, DieResult.result = 6})
      " {\"type\":\"PlayerRollsResult\",\"value\":{\"roller\":{\"type\":\"You\"},\"result\":6}} "
  -- CR 702.159a: nullary, the lights being the printing's.
  Spec.it s "Visit" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.Visit
      " {\"type\":\"Visit\"} "
  -- CR 701.32: nullary, the scheme being the ability's own.
  Spec.it s "SelfTurnedUpOffDeck" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfTurnedUpOffDeck
      " {\"type\":\"SelfTurnedUpOffDeck\"} "
  -- CR 701.31d: nullary, the plane being the ability's own.
  Spec.it s "SelfPlaneswalkedAwayFrom" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfPlaneswalkedAwayFrom
      " {\"type\":\"SelfPlaneswalkedAwayFrom\"} "
  -- CR 311.7: nullary, chaos ensuing for the whole table.
  Spec.it s "ChaosEnsues" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.ChaosEnsues
      " {\"type\":\"ChaosEnsues\"} "
  -- CR 901.8: the planeswalking ability's condition, PlayerBecomesMonarch's shape.
  Spec.it s "PlayerRollsPlaneswalker round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerRollsPlaneswalker PlayerRelation.You)
      " {\"type\":\"PlayerRollsPlaneswalker\",\"value\":{\"type\":\"You\"}} "
  -- CR 705.2. Both relations, PlayerBecomesMonarch's shape: Tavern Scoundrel is the
  -- You form.
  Spec.it s "PlayerWinsCoinFlip round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerWinsCoinFlip PlayerRelation.You)
      " {\"type\":\"PlayerWinsCoinFlip\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerWinsCoinFlip PlayerRelation.Opponent)
      " {\"type\":\"PlayerWinsCoinFlip\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 705.2's other outcome, the arm above's shape: Karplusan Minotaur is the
  -- You form.
  Spec.it s "PlayerLosesCoinFlip round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerLosesCoinFlip PlayerRelation.You)
      " {\"type\":\"PlayerLosesCoinFlip\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerLosesCoinFlip PlayerRelation.Opponent)
      " {\"type\":\"PlayerLosesCoinFlip\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 702.170a. Nullary, SelfRevealedForMiracle's shape: the ability is
  -- printed on the card that becomes plotted, so there is nothing to select
  -- among.
  Spec.it s "SelfBecomesPlotted round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfBecomesPlotted
      " {\"type\":\"SelfBecomesPlotted\"} "
  -- CR 603.12's reflexive, nullary: the whole condition is the word "when you
  -- do", and what it says about is the entry's existence.
  Spec.it s "Reflexive round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.Reflexive
      " {\"type\":\"Reflexive\"} "
  -- CR 701.3a read from the host. The Filter is over the ATTACHMENT, and Bramble
  -- Elemental's narrows to Auras, so the payload is a real HasSubtype rather than
  -- the trivial `And []`.
  Spec.it s "SelfBecomesAttachedBy round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesAttachedBy (Filter.HasSubtype Subtype.Aura))
      " {\"type\":\"SelfBecomesAttachedBy\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Aura\"}}} "
  -- CR 701.3a read from the ATTACHMENT, the mirror of the arm above: the tag is
  -- the only thing that separates the two, so both are round-tripped rather than
  -- one standing in for the other.
  Spec.it s "SelfBecomesAttachedTo round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesAttachedTo (Filter.HasCardType CardType.Creature))
      " {\"type\":\"SelfBecomesAttachedTo\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- CR 701.3d. Grafted Wargear says "from a permanent" and narrows nothing, so
  -- the trivial `And []` is the payload the card actually prints.
  Spec.it s "SelfBecomesUnattachedFrom round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesUnattachedFrom (Filter.And []))
      " {\"type\":\"SelfBecomesUnattachedFrom\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  Spec.it s "PlacesSticker round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlacesSticker (PlacesSticker.MkPlacesSticker PlayerRelation.You (Set.singleton StickerKind.Art) (Filter.And [])))
      " {\"type\":\"PlacesSticker\",\"value\":{\"placer\":{\"type\":\"You\"},\"kinds\":[{\"type\":\"Art\"}]}} "
  Spec.it s "PlacesSticker carries the object it went on" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlacesSticker (PlacesSticker.MkPlacesSticker PlayerRelation.You (Set.singleton StickerKind.Art) Filter.IsSource))
      " {\"type\":\"PlacesSticker\",\"value\":{\"placer\":{\"type\":\"You\"},\"kinds\":[{\"type\":\"Art\"}],\"object\":{\"type\":\"IsSource\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TriggerCondition.codec
