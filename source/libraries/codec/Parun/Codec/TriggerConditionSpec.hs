module Parun.Codec.TriggerConditionSpec where

import qualified Data.Set as Set
import qualified Data.Text as Text
import qualified Parun.Codec.TriggerCondition as TriggerCondition
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityAddsMana as AbilityAddsMana
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.AttackedPlayer as AttackedPlayer
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.CardLeavesZone as CardLeavesZone
import qualified Parun.Types.CardName as CardName
import qualified Parun.Types.CardPutIntoGraveyard as CardPutIntoGraveyard
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CardsPutIntoZone as CardsPutIntoZone
import qualified Parun.Types.CausedBy as CausedBy
import qualified Parun.Types.ClassLevel as ClassLevel
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.ControllerBecomesTarget as ControllerBecomesTarget
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterPlacement as CounterPlacement
import qualified Parun.Types.CreatureBecomesBlockedByAtLeast as CreatureBecomesBlockedByAtLeast
import qualified Parun.Types.CreatureExploits as CreatureExploits
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DealsDamageToPlayer as DealsDamageToPlayer
import qualified Parun.Types.DealtDamage as DealtDamage
import qualified Parun.Types.Designation as Designation
import qualified Parun.Types.DieResult as DieResult
import qualified Parun.Types.EndingStep as EndingStep
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaSpecification as ManaSpecification
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PermanentActed as PermanentActed
import qualified Parun.Types.PermanentAction as PermanentAction
import qualified Parun.Types.PermanentBecomesDesignated as PermanentBecomesDesignated
import qualified Parun.Types.PermanentDealsCombatDamageToPlayer as PermanentDealsCombatDamageToPlayer
import qualified Parun.Types.PermanentSacrificed as PermanentSacrificed
import qualified Parun.Types.PermanentTappedForMana as PermanentTappedForMana
import qualified Parun.Types.PermanentsBecomeTargeted as PermanentsBecomeTargeted
import qualified Parun.Types.PermanentsDealCombatDamageToPlayer as PermanentsDealCombatDamageToPlayer
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlacesSticker as PlacesSticker
import qualified Parun.Types.PlayerActed as PlayerActed
import qualified Parun.Types.PlayerAction as PlayerAction
import qualified Parun.Types.PlayerAttacksPlayer as PlayerAttacksPlayer
import qualified Parun.Types.PlayerAttacksWith as PlayerAttacksWith
import qualified Parun.Types.PlayerDrawsNthCard as PlayerDrawsNthCard
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlaysLand as PlaysLand
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RevealedThisWay as RevealedThisWay
import qualified Parun.Types.RoomIndex as RoomIndex
import qualified Parun.Types.SelfCountersReached as SelfCountersReached
import qualified Parun.Types.SelfCountersRemoved as SelfCountersRemoved
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.SpellCast as SpellCast
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.StepBegins as StepBegins
import qualified Parun.Types.StickerKind as StickerKind
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TapState as TapState
import qualified Parun.Types.TriggerCondition as TriggerCondition
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TurnScope as TurnScope
import qualified Parun.Types.Zone as Zone

-- | At least one case per TriggerCondition constructor. RoomFullyUnlocked gets
-- two, one per PlayerRelation, since CR 109.5's "you" against "an opponent" is
-- the whole of that payload.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TriggerCondition" $ do
  -- CR 603.6a.
  Spec.it s "SelfEnters" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfEnters
      " {\"type\":\"SelfEnters\"} "
  -- CR 603.6a's "[type]" is a whole Filter, so a nested And/Not has to survive
  -- the trip.
  Spec.it s "PermanentEnters round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentEnters (Filter.And [Filter.HasCardType CardType.Creature, Filter.Not Filter.IsSource]))
      " {\"type\":\"PermanentEnters\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}]}} "
  -- CR 603.2c: the batch reading is its own tag, PermanentsDie's reason.
  Spec.it s "PermanentsEnter round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentsEnter (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You]))
      " {\"type\":\"PermanentsEnter\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]}} "
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
  -- CR 603.2 / 509-510: the bearer dealt combat damage to a player the relation
  -- admits. BOTH relations, since the pool prints one of each: CR 702.70a's
  -- poisonous and Longtusk Cub say "a player", where Questing Beast says "an
  -- opponent", and a collapsed encoding would make the two one trigger.
  Spec.it s "SelfDealsCombatDamageToPlayer round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfDealsCombatDamageToPlayer PlayerRelation.AnyPlayer)
      " {\"type\":\"SelfDealsCombatDamageToPlayer\",\"value\":{\"type\":\"AnyPlayer\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfDealsCombatDamageToPlayer PlayerRelation.Opponent)
      " {\"type\":\"SelfDealsCombatDamageToPlayer\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 510.1b / 310.5 and CR 510.2: the two wider recipients, each its own tag.
  Spec.it s "SelfDealsCombatDamageToPlayerOrBattle" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfDealsCombatDamageToPlayerOrBattle
      " {\"type\":\"SelfDealsCombatDamageToPlayerOrBattle\"} "
  Spec.it s "DealsCombatDamage round-trips both actors" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DealsCombatDamage ActingPermanent.Self)
      " {\"type\":\"DealsCombatDamage\",\"value\":{\"type\":\"Self\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DealsCombatDamage (ActingPermanent.Matching (Filter.HeldBy Holder.Controller PlayerRelation.You)))
      " {\"type\":\"DealsCombatDamage\",\"value\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}}} "
  -- CR 603.2 / 120.1: the player-recipient pair without the combat narrowing --
  -- Akki Lavarunner's own condition. A separate TAG and not a flag on
  -- SelfDealsCombatDamageToPlayer, so a card written for one can never decode as
  -- the other.
  Spec.it s "DealsDamageToPlayer round-trips its actor and relation" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DealsDamageToPlayer (DealsDamageToPlayer.MkDealsDamageToPlayer ActingPermanent.Self PlayerRelation.Opponent))
      " {\"type\":\"DealsDamageToPlayer\",\"value\":{\"actor\":{\"type\":\"Self\"},\"recipient\":{\"type\":\"Opponent\"}}} "
  -- CR 120.3's other recipient: a bare tag for damage of any kind, the kind as
  -- the value otherwise.
  Spec.it s "SelfDealsDamageToCreature" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfDealsDamageToCreature Nothing)
      " {\"type\":\"SelfDealsDamageToCreature\"} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfDealsDamageToCreature (Just DamageKind.Combat))
      " {\"type\":\"SelfDealsDamageToCreature\",\"value\":{\"type\":\"Combat\"}} "
  Spec.it s "DealsDamage round-trips both actors" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DealsDamage ActingPermanent.Self)
      " {\"type\":\"DealsDamage\",\"value\":{\"type\":\"Self\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.DealsDamage (ActingPermanent.Matching (Filter.HasAttached Filter.IsSource)))
      " {\"type\":\"DealsDamage\",\"value\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasAttached\",\"value\":{\"type\":\"IsSource\"}}}} "
  -- CR 120.3: the same history read the other way round -- the permanent was
  -- DEALT damage.
  Spec.it s "IsDealtDamage round-trips both actors" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.IsDealtDamage ActingPermanent.Self)
      " {\"type\":\"IsDealtDamage\",\"value\":{\"type\":\"Self\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.IsDealtDamage (ActingPermanent.Matching (Filter.HasCardType CardType.Creature)))
      " {\"type\":\"IsDealtDamage\",\"value\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Lich's any damage, and Chandra's Spitfire's noncombat damage to an
  -- opponent.
  Spec.it s "PlayerIsDealtDamage round-trips both kinds" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerIsDealtDamage (PlayerIsDealtDamage.MkPlayerIsDealtDamage (DealtDamage.MkDealtDamage PlayerRelation.You Nothing) False))
      " {\"type\":\"PlayerIsDealtDamage\",\"value\":{\"dealt\":{\"player\":{\"type\":\"You\"}}}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerIsDealtDamage (PlayerIsDealtDamage.MkPlayerIsDealtDamage (DealtDamage.MkDealtDamage PlayerRelation.Opponent (Just DamageKind.Noncombat)) False))
      " {\"type\":\"PlayerIsDealtDamage\",\"value\":{\"dealt\":{\"player\":{\"type\":\"Opponent\"},\"kind\":{\"type\":\"Noncombat\"}}}} "
  -- The same event read by a bystander, carrying Tovolar's "you control" and
  -- Teysa's "to you": two relations, so a crossed codec would not round-trip.
  Spec.it s "PermanentDealsCombatDamageToPlayer round-trips with its Filter and recipient" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentDealsCombatDamageToPlayer (PermanentDealsCombatDamageToPlayer.MkPermanentDealsCombatDamageToPlayer (Filter.HeldBy Holder.Controller PlayerRelation.Opponent) PlayerRelation.You False))
      " {\"type\":\"PermanentDealsCombatDamageToPlayer\",\"value\":{\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"Opponent\"}}},\"recipient\":{\"type\":\"You\"}}} "
  -- CR 603.2c's batch reading of that same form, carrying the same Filter -- so a
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
  -- CR 702.179d: one or more opponents lost life during your turn.
  Spec.it s "OpponentLostLifeDuringYourTurn" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.OpponentLostLifeDuringYourTurn
      " {\"type\":\"OpponentLostLifeDuringYourTurn\"} "
  -- CR 702.29c.
  Spec.it s "SelfCycled" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfCycled
      " {\"type\":\"SelfCycled\"} "
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
  -- CR 701.9a's discard, self-scoped: Bartered Cow's "when you discard this
  -- card". Nullary, SelfCycled's shape -- the ability is printed on the card that
  -- is discarded, so there is nothing left to say.
  Spec.it s "SelfDiscarded" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfDiscarded
      " {\"type\":\"SelfDiscarded\"} "
  -- CR 702.35a's linked half, which is NOT SelfDiscarded: the card is exiled by
  -- madness's own replacement rather than by whatever else redirected the discard.
  Spec.it s "SelfExiledForMadness" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfExiledForMadness
      " {\"type\":\"SelfExiledForMadness\"} "
  -- CR 701.9a's discard. Both relations, since the PlayerRelation is the whole
  -- content of the "whenever an opponent discards" phrasing.
  Spec.it s "PlayerDiscards round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerDiscards PlayerRelation.Opponent)
      " {\"type\":\"PlayerDiscards\",\"value\":{\"type\":\"Opponent\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerDiscards PlayerRelation.You)
      " {\"type\":\"PlayerDiscards\",\"value\":{\"type\":\"You\"}} "
  -- CR 702.29a's cycling read as a discard, watched by a bystander: Prickly
  -- Marmoset's "whenever you cycle a card". Both relations, for PlayerDiscards'
  -- reason, and the tag is what keeps it distinct on the wire from that
  -- cause-blind sibling.
  Spec.it s "PlayerCycles round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerCycles PlayerRelation.You)
      " {\"type\":\"PlayerCycles\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerCycles PlayerRelation.Opponent)
      " {\"type\":\"PlayerCycles\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 603.2c's batch reading of PlayerDiscards, carrying the same payload, so
  -- the tag is all that keeps the two readings apart on the wire.
  Spec.it s "PlayerDiscardsCards round-trips under its own tag" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerDiscardsCards PlayerRelation.You)
      " {\"type\":\"PlayerDiscardsCards\",\"value\":{\"type\":\"You\"}} "
  -- CR 121.1's Nth draw of a turn. The relation and the ordinal are both content,
  -- and the ordinal is not 1, so a codec dropping it would fail rather than
  -- round-trip the default.
  Spec.it s "PlayerDrawsNthCard" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerDrawsNthCard (PlayerDrawsNthCard.MkPlayerDrawsNthCard PlayerRelation.You (Just 2)))
      " {\"type\":\"PlayerDrawsNthCard\",\"value\":{\"player\":{\"type\":\"You\"},\"nth\":2}} "
  -- CR 508.3a. Both frequencies, since "for the first time each turn" is a
  -- payload on this condition rather than a sibling one.
  Spec.it s "SelfAttacks round-trips both frequencies" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfAttacks TriggerFrequency.EveryTime)
      " {\"type\":\"SelfAttacks\",\"value\":{\"type\":\"EveryTime\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfAttacks TriggerFrequency.FirstTimeEachTurn)
      " {\"type\":\"SelfAttacks\",\"value\":{\"type\":\"FirstTimeEachTurn\"}} "
  -- CR 702.149a. A Filter over the OTHER attackers, where the sibling above takes
  -- a frequency and the one below counts the declaration.
  Spec.it s "SelfAttacksWithAnother" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfAttacksWithAnother (Filter.Measures (Measures.MkMeasures Measure.Power Comparison.GreaterThan (Operand.OfSource Measure.Power))))
      " {\"type\":\"SelfAttacksWithAnother\",\"value\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"GreaterThan\"},\"operand\":{\"type\":\"OfSource\",\"value\":{\"type\":\"Power\"}}}}} "
  -- CR 508.3a's second sentence. A Filter over the PERMANENT attacked, so the
  -- same wire shape as the arm above over a different subject -- Thrashing
  -- Frontliner's "a battle".
  Spec.it s "SelfAttacksPermanent" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfAttacksPermanent (Filter.HasCardType CardType.Battle))
      " {\"type\":\"SelfAttacksPermanent\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Battle\"}}} "
  -- CR 506.5. A Filter over the ATTACKER where the sibling above takes a
  -- frequency: "alone" is the constructor's own, so it has no encoding of its
  -- own here.
  Spec.it s "CreatureAttacksAlone" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CreatureAttacksAlone (Filter.HeldBy Holder.Controller PlayerRelation.You))
      " {\"type\":\"CreatureAttacksAlone\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}} "
  -- CR 508.3a's second sentence, nullary where the sibling above takes a Filter:
  -- CR 508.1a already makes every declared attacker a creature.
  Spec.it s "CreatureAttacksYou" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.CreatureAttacksYou
      " {\"type\":\"CreatureAttacksYou\"} "
  -- CR 508.3a read by a bystander, with a Filter over the attacker.
  Spec.it s "CreatureAttacks" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CreatureAttacks (Filter.HeldBy Holder.Controller PlayerRelation.You))
      " {\"type\":\"CreatureAttacks\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}} "
  -- CR 508.3d. All THREE relations, unlike PlayerCycles' two: rule 508.3d's
  -- "[a player]" is printed as "you" (Boggart Prankster), as "a player" (Avatar
  -- Roku, Firebender) and as "an opponent" (Ever-Watching Threshold).
  Spec.it s "PlayerAttacks round-trips all three relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerAttacks PlayerRelation.You)
      " {\"type\":\"PlayerAttacks\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerAttacks PlayerRelation.Opponent)
      " {\"type\":\"PlayerAttacks\",\"value\":{\"type\":\"Opponent\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerAttacks PlayerRelation.AnyPlayer)
      " {\"type\":\"PlayerAttacks\",\"value\":{\"type\":\"AnyPlayer\"}} "
  -- CR 508.3c, the arm above with a Filter and a floor beside the relation --
  -- Hermes, Overseer of Elpis' "whenever you attack with one or more Birds". A
  -- named object rather than a bare payload, which is what let the floor become
  -- a third key rather than a new wire shape.
  Spec.it s "PlayerAttacksWith" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerAttacksWith (PlayerAttacksWith.MkPlayerAttacksWith PlayerRelation.You (Filter.HasSubtype Subtype.Bird) 1))
      " {\"type\":\"PlayerAttacksWith\",\"value\":{\"player\":{\"type\":\"You\"},\"filter\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Bird\"}},\"attackers\":1}} "
  -- CR 508.3e, whose payload names BOTH subjects -- Seifer, Balamb Rival's
  -- You/AnyPlayer and Lulu, Stern Guardian's Opponent/You. The two keys hold
  -- DIFFERENT relations in each case, so a codec that crossed them would not
  -- round-trip. Not the same wire shape as PlayerAttacks above, whose tag
  -- differs and whose payload is a bare relation, so neither decodes as the
  -- other.
  Spec.it s "PlayerAttacksPlayer round-trips both subjects" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerAttacksPlayer (PlayerAttacksPlayer.MkPlayerAttacksPlayer PlayerRelation.You (AttackedPlayer.Related PlayerRelation.AnyPlayer)))
      " {\"type\":\"PlayerAttacksPlayer\",\"value\":{\"attacker\":{\"type\":\"You\"},\"attacked\":{\"type\":\"Related\",\"value\":{\"type\":\"AnyPlayer\"}}}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerAttacksPlayer (PlayerAttacksPlayer.MkPlayerAttacksPlayer PlayerRelation.Opponent (AttackedPlayer.Related PlayerRelation.You)))
      " {\"type\":\"PlayerAttacksPlayer\",\"value\":{\"attacker\":{\"type\":\"Opponent\"},\"attacked\":{\"type\":\"Related\",\"value\":{\"type\":\"You\"}}}} "
  -- CR 508.3b, nullary for the sibling above's reason and one of its own: the
  -- subject is whom the ability's own source is attached to.
  Spec.it s "AttachedPlayerIsAttacked" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.AttachedPlayerIsAttacked
      " {\"type\":\"AttachedPlayerIsAttacked\"} "
  -- Rule 508.3b's other two subjects, nullary for the arm above's reason: the
  -- subject is the ability's own source, so there is nothing to parameterize.
  Spec.it s "SelfIsAttacked" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfIsAttacked
      " {\"type\":\"SelfIsAttacked\"} "
  -- CR 702.105a, nullary: the comparison is over life totals, so there is nothing
  -- for a card to parameterize.
  Spec.it s "SelfAttacksPlayerWithMostLife" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfAttacksPlayerWithMostLife
      " {\"type\":\"SelfAttacksPlayerWithMostLife\"} "
  Spec.it s "SelfAttacksWhile" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfAttacksWhile (Condition.Compares (Compares.MkCompares (Quantity.Literal 0) Comparison.Exactly (Quantity.Literal 0))))
      " {\"type\":\"SelfAttacksWhile\",\"value\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":0},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}} "
  Spec.it s "SelfAttacksWhileSaddled" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfAttacksWhileSaddled
      " {\"type\":\"SelfAttacksWhileSaddled\"} "
  -- CR 509.3a, and nullary where its mirror is not: rule 509.3a's
  -- once-each-combat is not a frequency a card chooses.
  Spec.it s "SelfBlocks" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfBlocks
      " {\"type\":\"SelfBlocks\"} "
  -- CR 509.3a read by a bystander, with a Filter over the blocker.
  Spec.it s "CreatureBlocks" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CreatureBlocks (Filter.HasAttached Filter.IsSource))
      " {\"type\":\"CreatureBlocks\",\"value\":{\"type\":\"HasAttached\",\"value\":{\"type\":\"IsSource\"}}} "
  -- CR 509.3b, which carries a Filter over the ATTACKER the bearer blocked --
  -- Netcaster Spider's "a creature with flying". The attacker is also a BINDING,
  -- and that is a separate thing the payload reads rather than an encoding of it.
  Spec.it s "SelfBlocksCreature" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBlocksCreature (Filter.HasKeyword Keyword.Flying))
      " {\"type\":\"SelfBlocksCreature\",\"value\":{\"type\":\"HasKeyword\",\"value\":{\"type\":\"Flying\"}}} "
  -- CR 509.3e, and NOT nullary: the floor is the card's own number.
  Spec.it s "SelfBlocksAtLeast" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBlocksAtLeast 2)
      " {\"type\":\"SelfBlocksAtLeast\",\"value\":2} "
  -- CR 509.3e's filtered form, whose tag must stay distinct from the counted one
  -- above: the two read the same grouped event and differ only in what they ask
  -- of it.
  Spec.it s "SelfBlocksOneOrMore" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBlocksOneOrMore (Filter.HasColor Color.Black))
      " {\"type\":\"SelfBlocksOneOrMore\",\"value\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}}} "
  -- CR 509.3c, nullary for the same reason, and a distinct tag from the sibling
  -- above: the two name opposite sides of one declaration.
  Spec.it s "SelfBecomesBlocked" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfBecomesBlocked
      " {\"type\":\"SelfBecomesBlocked\"} "
  -- CR 509.3d, which carries a Filter over the BLOCKER where its once-each-combat
  -- sibling above carries nothing -- rule 702.25a's "without flanking".
  Spec.it s "SelfBecomesBlockedBy" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesBlockedBy (Filter.Not (Filter.HasKeyword Keyword.Flanking)))
      " {\"type\":\"SelfBecomesBlockedBy\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"HasKeyword\",\"value\":{\"type\":\"Flanking\"}}}} "
  -- CR 509.3e read from the attacking side. A distinct tag from the per-blocker
  -- form above, which carries the same payload and differs only in arity.
  Spec.it s "SelfBecomesBlockedByOneOrMore" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesBlockedByOneOrMore (Filter.HasColor Color.Black))
      " {\"type\":\"SelfBecomesBlockedByOneOrMore\",\"value\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}}} "
  -- The same rule read by a bystander: a PAYLOAD OBJECT rather than a bare
  -- Filter, since this form carries both whom the attacker attacked and the
  -- floor on the blockers.
  Spec.it s "CreatureBecomesBlockedByAtLeast" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CreatureBecomesBlockedByAtLeast (CreatureBecomesBlockedByAtLeast.MkCreatureBecomesBlockedByAtLeast PlayerRelation.Opponent 2))
      " {\"type\":\"CreatureBecomesBlockedByAtLeast\",\"value\":{\"attacked\":{\"type\":\"Opponent\"},\"blockers\":2}} "
  -- CR 509.1h's unblocked branch, nullary like the blocked one: "attacks and
  -- isn't blocked" has no per-blocker reading to carry a Filter for.
  Spec.it s "SelfAttacksUnblocked" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfAttacksUnblocked
      " {\"type\":\"SelfAttacksUnblocked\"} "
  Spec.it s "SelfLeavesGraveyard" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfLeavesGraveyard
      " {\"type\":\"SelfLeavesGraveyard\"} "
  -- CR 113.6k's condition, which names a zone pair rather than the battlefield.
  Spec.it s "SelfPutIntoGraveyardFromLibrary" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfPutIntoGraveyardFromLibrary
      " {\"type\":\"SelfPutIntoGraveyardFromLibrary\"} "
  -- The same rule with no origin zone at all -- a separate tag from the one
  -- above, which it is a superset of: the two must never decode to each other.
  Spec.it s "SelfPutIntoGraveyardFromAnywhere" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfPutIntoGraveyardFromAnywhere
      " {\"type\":\"SelfPutIntoGraveyardFromAnywhere\"} "
  -- CR 702.55a's second sentence, a third tag over the same destination: rule
  -- 608.2n's cause is what it adds, so it must never decode to either above.
  Spec.it s "SelfPutIntoGraveyardDuringResolution" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfPutIntoGraveyardDuringResolution
      " {\"type\":\"SelfPutIntoGraveyardDuringResolution\"} "
  -- CR 603.6c's second written form, abbreviated by CR 700.4 to "dies".
  Spec.it s "SelfDies" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfDies
      " {\"type\":\"SelfDies\"} "
  -- CR 712.21's Example condition, which carries a Filter over the ARRIVING card
  -- where PermanentDies below filters the departed permanent -- a separate tag,
  -- since the two admit different events.
  Spec.it s "CardPutIntoGraveyard round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CardPutIntoGraveyard (CardPutIntoGraveyard.MkCardPutIntoGraveyard (Filter.Not Filter.IsSource) Set.empty))
      " {\"type\":\"CardPutIntoGraveyard\",\"value\":{\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}}} "
  -- The same written form read by a bystander, which carries a Filter where
  -- SelfDies above carries nothing -- so it is a separate tag, and "another"
  -- lives inside that Filter.
  Spec.it s "PermanentDies round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentDies (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You, Filter.Not Filter.IsSource]))
      " {\"type\":\"PermanentDies\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}]}} "
  -- CR 603.2c's batch reading of that same form, carrying the same Filter -- so a
  -- separate tag is the only thing that keeps the once-per-batch card and the
  -- once-per-death card apart on the wire.
  Spec.it s "PermanentsDie round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentsDie (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You, Filter.Not Filter.IsSource]))
      " {\"type\":\"PermanentsDie\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}]}} "
  -- CR 603.6c's first written form, a separate tag from SelfDies above: the two
  -- must never decode to each other.
  Spec.it s "SelfLeavesTheBattlefield" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfLeavesTheBattlefield
      " {\"type\":\"SelfLeavesTheBattlefield\"} "
  Spec.it s "SelfPutFromBattlefieldInto" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfPutFromBattlefieldInto (OwnedZone.MkOwnedZone {OwnedZone.zone = Zone.Graveyard, OwnedZone.owner = PlayerRelation.You}))
      " {\"type\":\"SelfPutFromBattlefieldInto\",\"value\":{\"owner\":{\"type\":\"You\"},\"zone\":{\"type\":\"Graveyard\"}}} "
  -- The same written form read by a bystander, PermanentDies' relationship to
  -- SelfDies one rule wider: a separate tag carrying the Filter that holds
  -- "another".
  Spec.it s "PermanentLeavesTheBattlefield round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentLeavesTheBattlefield (Filter.Not Filter.IsSource))
      " {\"type\":\"PermanentLeavesTheBattlefield\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}}} "
  -- The arm above with one destination named, so a separate tag: the Filter is a
  -- predicate over the object and could not carry where the object went. Justice,
  -- Vance Astrovik's printed Filter, which is what the corpus spells.
  Spec.it s "PermanentReturnedToHand round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentReturnedToHand (Filter.And [Filter.Not Filter.IsSource, Filter.HeldBy Holder.Controller PlayerRelation.You]))
      " {\"type\":\"PermanentReturnedToHand\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"Not\",\"value\":{\"type\":\"IsSource\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]}} "
  -- CR 603.2c's batch reading of that same form, carrying the same Filter -- so
  -- a separate tag is the only thing that keeps Tameshi, Reality Architect's
  -- once-per-batch card and Justice's once-per-permanent card apart on the wire.
  Spec.it s "PermanentsReturnedToHand round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentsReturnedToHand (Filter.Not (Filter.HasCardType CardType.Creature)))
      " {\"type\":\"PermanentsReturnedToHand\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- CR 603.10a's third family, whose payload is a record rather than a bare
  -- Filter: Kishla Skimmer's "your graveyard" is `whose` and its "during your
  -- turn" is the TurnScope beside it.
  Spec.it s "CardLeavesZone round-trips with its Filter, TurnScope and zone" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CardLeavesZone (CardLeavesZone.MkCardLeavesZone (Filter.Not Filter.IsToken) TurnScope.ControllersTurn Zone.Graveyard Nothing (Just PlayerRelation.You)))
      " {\"type\":\"CardLeavesZone\",\"value\":{\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}},\"scope\":{\"type\":\"ControllersTurn\"},\"from\":{\"type\":\"Graveyard\"},\"whose\":{\"type\":\"You\"}}} "
  -- CR 603.2c's batch reading of the family above, carrying the same record:
  -- Spirit Mascot's "your graveyard" is `whose` and its silence about turns is
  -- the EachTurn beside it.
  Spec.it s "CardsLeaveZone round-trips with its Filter, TurnScope and zones" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CardsLeaveZone (CardLeavesZone.MkCardLeavesZone (Filter.Not Filter.IsToken) TurnScope.EachTurn Zone.Graveyard (Just Zone.Exile) (Just PlayerRelation.You)))
      " {\"type\":\"CardsLeaveZone\",\"value\":{\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}},\"scope\":{\"type\":\"EachTurn\"},\"from\":{\"type\":\"Graveyard\"},\"to\":{\"type\":\"Exile\"},\"whose\":{\"type\":\"You\"}}} "
  -- The arrival-side twin: Dutiful Knowledge Seeker's "cards" put into a library
  -- from anywhere, so no origin zone is written.
  Spec.it s "CardsPutIntoZone round-trips with its Filter and destination" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CardsPutIntoZone (CardsPutIntoZone.MkCardsPutIntoZone (Filter.Not Filter.IsToken) TurnScope.EachTurn Set.empty Zone.Library))
      " {\"type\":\"CardsPutIntoZone\",\"value\":{\"filter\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}},\"scope\":{\"type\":\"EachTurn\"},\"to\":{\"type\":\"Library\"}}} "
  -- CR 700.4's death read off the enchanted permanent. Nullary: the link it
  -- matches on is board state, HauntedCreatureDies' reason.
  Spec.it s "AttachedCreatureDies" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.AttachedCreatureDies
      " {\"type\":\"AttachedCreatureDies\"} "
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
  -- CR 106.12a's tap for mana read off the attachment link, nullary for
  -- AttachedCreatureDies' reason.
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
  -- CR 702.55b/702.55c's exile-zone death watch. Nullary: the link it matches on
  -- is board state, so nothing about it rides the condition.
  Spec.it s "HauntedCreatureDies" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.HauntedCreatureDies
      " {\"type\":\"HauntedCreatureDies\"} "
  -- CR 701.6a's countering. Both relations, for the same reason
  -- PlayerDiscards has both.
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
  -- CR 119.9's life-gain trigger. Both relations, for the same reason.
  Spec.it s "PlayerGainsLife round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerGainsLife PlayerRelation.You)
      " {\"type\":\"PlayerGainsLife\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerGainsLife PlayerRelation.Opponent)
      " {\"type\":\"PlayerGainsLife\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 603.2c's batch reading of the arm above. A DIFFERENT tag carrying the SAME
  -- payload, which is the whole hazard: a codec that folded the two would make
  -- "each player gains 4 life" fire a per-seat card once and a batch card three
  -- times, or the other way about.
  Spec.it s "PlayersGainLife round-trips under its own tag" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayersGainLife PlayerRelation.AnyPlayer)
      " {\"type\":\"PlayersGainLife\",\"value\":{\"type\":\"AnyPlayer\"}} "
  -- The life-LOSS trigger. A DIFFERENT tag from PlayerGainsLife above and the
  -- same payload shape, so the two must never decode to each other -- the same
  -- hazard GameEvent's LifeLost/LifeGained pair carries.
  Spec.it s "PlayerLosesLife round-trips both relations" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerLosesLife PlayerRelation.You)
      " {\"type\":\"PlayerLosesLife\",\"value\":{\"type\":\"You\"}} "
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PlayerLosesLife PlayerRelation.Opponent)
      " {\"type\":\"PlayerLosesLife\",\"value\":{\"type\":\"Opponent\"}} "
  -- CR 714.2b. The payload is the counter KIND then the chapter number, in that
  -- order, since a Saga's chapters are told apart by the number alone.
  Spec.it s "SelfCountersReached round-trips its kind and its chapter number" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfCountersReached (SelfCountersReached.MkSelfCountersReached CounterKind.Lore 3))
      " {\"type\":\"SelfCountersReached\",\"value\":{\"kind\":{\"type\":\"Lore\"},\"amount\":3}} "
  -- CR 716.2a. The payload is the bar's printed level number and nothing else:
  -- the ability is printed on the Class whose level changes, so there is nothing
  -- to select among.
  Spec.it s "SelfBecomesClassLevel round-trips its level" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesClassLevel (ClassLevel.MkClassLevel 2))
      " {\"type\":\"SelfBecomesClassLevel\",\"value\":2} "
  -- CR 310.12b. The payload is the counter kind: "the last" needs no number.
  Spec.it s "SelfLastCounterRemoved round-trips its kind" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfLastCounterRemoved (SelfCountersRemoved.MkSelfCountersRemoved CounterKind.Time))
      " {\"type\":\"SelfLastCounterRemoved\",\"value\":{\"kind\":{\"type\":\"Time\"}}} "
  -- Its any-amount mirror, sharing the payload and differing only in the tag --
  -- a DIFFERENT kind here, so a codec that crossed the two arms could not pass
  -- both cases.
  Spec.it s "SelfCountersRemoved round-trips its kind" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfCountersRemoved (SelfCountersRemoved.MkSelfCountersRemoved CounterKind.Loyalty))
      " {\"type\":\"SelfCountersRemoved\",\"value\":{\"kind\":{\"type\":\"Loyalty\"}}} "
  -- Its per-counter reading (CR 603.2c), the same payload under its own tag,
  -- on a fourth kind.
  Spec.it s "SelfCounterRemoved round-trips its kind" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfCounterRemoved (SelfCountersRemoved.MkSelfCountersRemoved CounterKind.PlusOnePlusOne))
      " {\"type\":\"SelfCounterRemoved\",\"value\":{\"kind\":{\"type\":\"PlusOnePlusOne\"}}} "
  -- CR 603.2c's batch placement, whose payload is an OBJECT rather than a bare
  -- kind: a third counter kind and a Filter, so a codec that crossed this arm
  -- with either mirror above could not pass all three cases.
  Spec.it s "PermanentsGetCounters round-trips its kind and its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      ( TriggerCondition.PermanentsGetCounters
          ( CounterPlacement.MkCounterPlacement
              { CounterPlacement.kind = CounterKind.MinusOneMinusOne,
                CounterPlacement.permanents = Filter.HasCardType CardType.Creature
              }
          )
      )
      " {\"type\":\"PermanentsGetCounters\",\"value\":{\"kind\":{\"type\":\"MinusOneMinusOne\"},\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- The same payload under CR 603.2c's OTHER scope, whose tag differs from the
  -- arm above by one letter: a codec that crossed the two would round-trip the
  -- value and hand back the wrong reading, which only a pair of cases can catch.
  Spec.it s "PermanentGetsCounters round-trips under its own tag" $
    Common.assertCodec
      s
      TriggerCondition.codec
      ( TriggerCondition.PermanentGetsCounters
          ( CounterPlacement.MkCounterPlacement
              { CounterPlacement.kind = CounterKind.MinusOneMinusOne,
                CounterPlacement.permanents = Filter.HasCardType CardType.Creature
              }
          )
      )
      " {\"type\":\"PermanentGetsCounters\",\"value\":{\"kind\":{\"type\":\"MinusOneMinusOne\"},\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- CR 601.2i. A PAIR: a Filter over the SPELL, holding Young Pyromancer's two
  -- printed narrowings -- who cast it and what it was -- plus the TurnScope,
  -- which is the axis the Filter cannot carry. Young Pyromancer prints no turn,
  -- so EachTurn is its half.
  Spec.it s "SpellCast round-trips with its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellCast (SpellCast.MkSpellCast (Filter.And [Filter.HeldBy Holder.Controller PlayerRelation.You, Filter.Or [Filter.HasCardType CardType.Instant, Filter.HasCardType CardType.Sorcery]]) TurnScope.EachTurn Nothing Nothing Nothing False))
      " {\"type\":\"SpellCast\",\"value\":{\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},{\"type\":\"Or\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}},{\"type\":\"HasCardType\",\"value\":{\"type\":\"Sorcery\"}}]}]},\"scope\":{\"type\":\"EachTurn\"}}} "
  -- The other half moved on its own, over the plainest Filter there is: Brineborn
  -- Cutthroat's "during an opponent's turn", which no Filter could have said.
  Spec.it s "SpellCast round-trips an opponent's-turn scope" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SpellCast (SpellCast.MkSpellCast (Filter.HeldBy Holder.Controller PlayerRelation.You) TurnScope.OpponentsTurn Nothing Nothing Nothing False))
      " {\"type\":\"SpellCast\",\"value\":{\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},\"scope\":{\"type\":\"OpponentsTurn\"}}} "
  -- CR 601.2i read off the spell itself, Desolation Twin's "when you cast this
  -- spell": nullary, since "this spell" needs neither Filter nor TurnScope.
  -- CR 702.21a's relation is on the TARGETING side -- the opponent whose spell
  -- named the bearer -- so the payload is the same PlayerRelation
  -- SpellOrAbilityCounters carries and never a Filter over the bearer.
  Spec.it s "SelfBecomesTargeted" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfBecomesTargeted PlayerRelation.Opponent)
      " {\"type\":\"SelfBecomesTargeted\",\"value\":{\"type\":\"Opponent\"}} "
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
  -- CR 603.2c's batch reading of the same rule with a Filter over the targeted
  -- permanents: Professor Hojo's. Hand-written like every Arm.tagged arm.
  Spec.it s "PermanentsBecomeTargeted round-trips with its Filter and its kind" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentsBecomeTargeted (PermanentsBecomeTargeted.MkPermanentsBecomeTargeted {PermanentsBecomeTargeted.filter = Filter.HeldBy Holder.Controller PlayerRelation.You, PermanentsBecomeTargeted.kind = Just StackObjectKind.ActivatedAbility}))
      " {\"type\":\"PermanentsBecomeTargeted\",\"value\":{\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},\"kind\":{\"type\":\"ActivatedAbility\"}}} "
  Spec.it s "PermanentBecomesTargeted round-trips with its Filter and its kind" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentBecomesTargeted (PermanentsBecomeTargeted.MkPermanentsBecomeTargeted {PermanentsBecomeTargeted.filter = Filter.HeldBy Holder.Controller PlayerRelation.You, PermanentsBecomeTargeted.kind = Just StackObjectKind.Spell}))
      " {\"type\":\"PermanentBecomesTargeted\",\"value\":{\"filter\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}},\"kind\":{\"type\":\"Spell\"}}} "
  Spec.it s "SelfCast" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfCast
      " {\"type\":\"SelfCast\"} "
  -- CR 709.5h. The payload is the DOOR's own name (CR 709.4a), which is what
  -- separates two unlock triggers printed on one Room.
  Spec.it s "SelfHalfUnlocked round-trips its door" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfHalfUnlocked (CardName.MkCardName (Text.pack "Steaming Sauna")))
      " {\"type\":\"SelfHalfUnlocked\",\"value\":\"Steaming Sauna\"} "
  -- CR 701.27e, SelfHalfUnlocked's shape: a self-scoped condition whose payload
  -- is the face named.
  Spec.it s "SelfTransformedInto round-trips the face it names" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.SelfTransformedInto (CardName.MkCardName (Text.pack "Blightsower Thallid")))
      " {\"type\":\"SelfTransformedInto\",\"value\":\"Blightsower Thallid\"} "
  -- The same rule read by a bystander, whose payload is a Filter instead: the TAG
  -- is the whole difference between the two, so both are pinned.
  Spec.it s "PermanentTransforms round-trips its Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentTransforms (Filter.Not (Filter.HasSubtype Subtype.Human)))
      " {\"type\":\"PermanentTransforms\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Human\"}}}} "
  -- CR 709.5i. The payload is a PlayerRelation, read against the controller of the
  -- permanent that became fully unlocked. BOTH relations, since the two are what
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
      (TriggerCondition.CausedBy CausedBy.MkCausedBy {CausedBy.controller = PlayerRelation.Opponent, CausedBy.condition = TriggerCondition.PlayerDiscards PlayerRelation.You})
      " {\"type\":\"CausedBy\",\"value\":{\"controller\":{\"type\":\"Opponent\"},\"condition\":{\"type\":\"PlayerDiscards\",\"value\":{\"type\":\"You\"}}}} "
  Spec.it s "AnyOf round-trips both of its branches" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.AnyOf [TriggerCondition.PermanentEnters (Filter.HasCardType CardType.Enchantment), TriggerCondition.RoomFullyUnlocked PlayerRelation.You])
      " {\"type\":\"AnyOf\",\"value\":[{\"type\":\"PermanentEnters\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Enchantment\"}}},{\"type\":\"RoomFullyUnlocked\",\"value\":{\"type\":\"You\"}}]} "
  -- CR 708.7. Nullary: the bearer is CR 113.7a's source and the rule leaves
  -- nothing else for the condition to name.
  Spec.it s "SelfTurnedFaceUp" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfTurnedFaceUp
      " {\"type\":\"SelfTurnedFaceUp\"} "
  -- CR 708.7's other written form. Aven Farseer says only "a permanent", which is
  -- Filter's trivial `And []` -- so the encoded value carries an EMPTY filter
  -- rather than no filter at all, which is what keeps the narrowed printings
  -- below spellable in the same constructor.
  Spec.it s "PermanentTurnedFaceUp round-trips with the trivial Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentTurnedFaceUp (Filter.And []))
      " {\"type\":\"PermanentTurnedFaceUp\",\"value\":{\"type\":\"And\",\"value\":[]}} "
  -- The same condition NARROWED, which is Deathmist Raptor's "whenever a permanent
  -- you control is turned face up": the Filter is the whole difference between the
  -- two printings, so it has to survive both directions.
  Spec.it s "PermanentTurnedFaceUp round-trips with a narrowing Filter" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentTurnedFaceUp (Filter.HeldBy Holder.Controller PlayerRelation.You))
      " {\"type\":\"PermanentTurnedFaceUp\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}} "
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
  -- CR 702.110b's marker, self-scoped, so nullary.
  Spec.it s "SelfExploits" $
    Common.assertCodec
      s
      TriggerCondition.codec
      TriggerCondition.SelfExploits
      " {\"type\":\"SelfExploits\"} "
  -- CR 702.110b's bystander reading, Skull Skaab's two Filters.
  Spec.it s "CreatureExploits" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.CreatureExploits (CreatureExploits.MkCreatureExploits (Filter.HasCardType CardType.Creature) (Filter.Not Filter.IsToken)))
      " {\"type\":\"CreatureExploits\",\"value\":{\"exploiter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"exploited\":{\"type\":\"Not\",\"value\":{\"type\":\"IsToken\"}}}} "
  -- CR 702.122e's marker, self-scoped but carrying a frequency for SelfAttacks'
  -- reason above -- Mighty Servant of Leuk-o prints "for the first time each
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
  -- CR 702.122b's crewer side, nullary for SelfExploits' reason above; the arm
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
      (TriggerCondition.PermanentSacrificed (PermanentSacrificed.MkPermanentSacrificed PlayerRelation.Opponent (Filter.HasCardType CardType.Artifact)))
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
  -- CR 725.1's crowning. Both relations, for the same reason PlayerDiscards has
  -- both: the PlayerRelation is the whole difference between "whenever you
  -- become the monarch" and "whenever an opponent becomes the monarch", so a
  -- codec that dropped it would silently turn one printing into the other.
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
  -- CR 701.66a's slot-named condition, the arm above's wire shape. No card prints
  -- it -- Parun.Engine.Earthbend mints the only ability that carries it -- and it
  -- must not collapse into LoseControlOfBound, which shares the payload exactly.
  Spec.it s "BoundDiesOrIsExiled round-trips its slot, and is not LoseControlOfBound" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BoundDiesOrIsExiled (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"BoundDiesOrIsExiled\",\"value\":\"target\"} "
    Spec.assertBool
      s
      (TriggerCondition.BoundDiesOrIsExiled (SlotName.MkSlotName (Text.pack "target")) /= TriggerCondition.LoseControlOfBound (SlotName.MkSlotName (Text.pack "target")))
      "BoundDiesOrIsExiled and LoseControlOfBound of the same slot are different conditions"
  -- CR 700.4's slot-named condition, the arm above narrowed to a death, and the
  -- one of the three card data writes (Whippoorwill). It shares the payload with
  -- both of the others, so it must not collapse into either.
  Spec.it s "BoundDies round-trips its slot, and is not BoundDiesOrIsExiled" $ do
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.BoundDies (SlotName.MkSlotName (Text.pack "target")))
      " {\"type\":\"BoundDies\",\"value\":\"target\"} "
    Spec.assertBool
      s
      (TriggerCondition.BoundDies (SlotName.MkSlotName (Text.pack "target")) /= TriggerCondition.BoundDiesOrIsExiled (SlotName.MkSlotName (Text.pack "target")))
      "BoundDies and BoundDiesOrIsExiled of the same slot are different conditions"
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
  -- CR 702.170a. Nullary, SelfCycled's shape: the ability is printed on the card
  -- that becomes plotted, so there is nothing to select among.
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
  -- CR 509.3d's bystander form. A real Filter rather than the trivial `And []`:
  -- the payload is over the ATTACKER, and CR 701.54c's is a Ring-bearer test.
  Spec.it s "PermanentBecomesBlockedBy round-trips" $
    Common.assertCodec
      s
      TriggerCondition.codec
      (TriggerCondition.PermanentBecomesBlockedBy Filter.IsRingBearer)
      " {\"type\":\"PermanentBecomesBlockedBy\",\"value\":{\"type\":\"IsRingBearer\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TriggerCondition.codec
