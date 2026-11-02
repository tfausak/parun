module Parun.Codec.RuleAbilitiesSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.RuleAbilities as RuleAbilities
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActivationProhibition as ActivationProhibition
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.AttachRestriction as AttachRestriction
import qualified Parun.Types.AttackCost as AttackCost
import qualified Parun.Types.AttackCostScope as AttackCostScope
import qualified Parun.Types.AttackPermission as AttackPermission
import qualified Parun.Types.AttackRequirement as AttackRequirement
import qualified Parun.Types.BlockCost as BlockCost
import qualified Parun.Types.BlockPermission as BlockPermission
import qualified Parun.Types.BlockRequirement as BlockRequirement
import qualified Parun.Types.CombatRestriction as CombatRestriction
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterRestriction as CounterRestriction
import qualified Parun.Types.CrewRestriction as CrewRestriction
import qualified Parun.Types.EntryRestriction as EntryRestriction
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.PerCreature as PerCreature
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RequirementArity as RequirementArity
import qualified Parun.Types.RuleAbilities as RuleAbilities
import qualified Parun.Types.SacrificeRestriction as SacrificeRestriction
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.TargetRestriction as TargetRestriction
import qualified Parun.Types.UntapHold as UntapHold
import qualified Parun.Types.UntapRestriction as UntapRestriction
import qualified Parun.Types.Zone as Zone

-- | Every one of the twelve keys defaults to the empty list, so one fixture with
-- all twelve populated is what holds each key's spelling to
-- Parun.Codec.Face's -- the two write the same wire shape and a copy snapshot
-- would otherwise round trip through a key no card ever writes.

-- | The values Parun.Codec.FaceSpec's populated face carries, so a drift between
-- the two encodings shows up as a difference in this file.
testRuleAbilities :: RuleAbilities.RuleAbilities
testRuleAbilities =
  RuleAbilities.MkRuleAbilities
    { RuleAbilities.activationProhibitions = [ActivationProhibition.MkActivationProhibition Affected.Attached Nothing Nothing],
      RuleAbilities.attachRestrictions = [AttachRestriction.MkAttachRestriction Affected.Attached (Filter.HasSubtype Subtype.Aura)],
      RuleAbilities.attackCosts = [AttackCost.MkAttackCost Affected.Attached (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])) [])) AttackCostScope.Controller Nothing],
      RuleAbilities.attackPermissions = [AttackPermission.MkAttackPermission Affected.Attached Nothing],
      RuleAbilities.attackRequirements = [AttackRequirement.MkAttackRequirement Affected.Attached Nothing Nothing RequirementArity.EachSubject],
      RuleAbilities.blockCosts = [BlockCost.MkBlockCost Affected.Attached (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 3])) [])) Nothing Nothing],
      RuleAbilities.blockPermissions = [BlockPermission.MkBlockPermission Affected.Attached (Just (Quantity.Literal 1)) Nothing],
      RuleAbilities.blockRequirements = [BlockRequirement.MkBlockRequirement Nothing (Just Affected.Attached) Nothing RequirementArity.EachSubject],
      RuleAbilities.combatRestrictions = [CombatRestriction.CantAttack (AffectedUnless.MkAffectedUnless Affected.Attached Nothing Nothing Nothing)],
      RuleAbilities.counterRestrictions = [CounterRestriction.MkCounterRestriction Affected.Attached (Just CounterKind.MinusOneMinusOne)],
      RuleAbilities.crewRestrictions = [CrewRestriction.MkCrewRestriction Affected.Attached],
      RuleAbilities.entryRestrictions = [EntryRestriction.MkEntryRestriction Affected.Attached (Set.singleton Zone.Graveyard)],
      RuleAbilities.sacrificeRestrictions = [SacrificeRestriction.MkSacrificeRestriction Affected.Attached],
      RuleAbilities.targetRestrictions = [TargetRestriction.MkTargetRestriction Affected.Attached StackObjectKind.Spell (Filter.And [])],
      RuleAbilities.untapRestrictions = [UntapRestriction.MkUntapRestriction Affected.Attached UntapHold.Forbidden Nothing]
    }

testRuleAbilitiesJson :: String
testRuleAbilitiesJson =
  "{\"activationProhibitions\":[{\"affected\":{\"type\":\"Attached\"}}],"
    <> "\"attachRestrictions\":[{\"affected\":{\"type\":\"Attached\"},\"attachers\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Aura\"}}}],"
    <> "\"attackCosts\":[{\"subject\":{\"type\":\"Attached\"},\"perAttacker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":2}]}},\"scope\":{\"type\":\"Controller\"}}],"
    <> "\"attackPermissions\":[{\"affected\":{\"type\":\"Attached\"}}],"
    <> "\"attackRequirements\":[{\"subject\":{\"type\":\"Attached\"}}],"
    <> "\"blockCosts\":[{\"subject\":{\"type\":\"Attached\"},\"perBlocker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":3}]}}}],"
    <> "\"blockPermissions\":[{\"affected\":{\"type\":\"Attached\"},\"additional\":{\"type\":\"Literal\",\"value\":1}}],"
    <> "\"blockRequirements\":[{\"attacker\":{\"type\":\"Attached\"}}],"
    <> "\"combatRestrictions\":[{\"type\":\"CantAttack\",\"value\":{\"affected\":{\"type\":\"Attached\"}}}],"
    <> "\"counterRestrictions\":[{\"affected\":{\"type\":\"Attached\"},\"kind\":{\"type\":\"MinusOneMinusOne\"}}],"
    <> "\"crewRestrictions\":[{\"affected\":{\"type\":\"Attached\"}}],"
    <> "\"entryRestrictions\":[{\"affected\":{\"type\":\"Attached\"},\"origins\":[{\"type\":\"Graveyard\"}]}],"
    <> "\"sacrificeRestrictions\":[{\"affected\":{\"type\":\"Attached\"}}],"
    <> "\"targetRestrictions\":[{\"affected\":{\"type\":\"Attached\"},\"kind\":{\"type\":\"Spell\"}}],"
    <> "\"untapRestrictions\":[{\"affected\":{\"type\":\"Attached\"}}]}"

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RuleAbilities" $ do
  Spec.it s "MkRuleAbilities, every one of the fifteen lists populated" $
    Common.assertCodec s RuleAbilities.codec testRuleAbilities testRuleAbilitiesJson
  Spec.it s "an empty bundle omits every key" $
    Common.assertCodec s RuleAbilities.codec mempty " {} "
