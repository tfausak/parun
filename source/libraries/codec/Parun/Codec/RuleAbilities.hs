{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RuleAbilities where

import qualified Parun.Codec.ActivationProhibition as ActivationProhibition
import qualified Parun.Codec.AttachRestriction as AttachRestriction
import qualified Parun.Codec.AttackCost as AttackCost
import qualified Parun.Codec.AttackPermission as AttackPermission
import qualified Parun.Codec.AttackRequirement as AttackRequirement
import qualified Parun.Codec.BlockCost as BlockCost
import qualified Parun.Codec.BlockPermission as BlockPermission
import qualified Parun.Codec.BlockRequirement as BlockRequirement
import qualified Parun.Codec.CombatRestriction as CombatRestriction
import qualified Parun.Codec.CounterRestriction as CounterRestriction
import qualified Parun.Codec.CrewRestriction as CrewRestriction
import qualified Parun.Codec.EntryRestriction as EntryRestriction
import qualified Parun.Codec.SacrificeRestriction as SacrificeRestriction
import qualified Parun.Codec.TargetRestriction as TargetRestriction
import qualified Parun.Codec.UntapRestriction as UntapRestriction
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RuleAbilities as RuleAbilities

-- | The field names Parun.Codec.Face already writes, so a copy snapshot's
-- bundle round-trips through the same spellings a card's own face does.
codec :: Codec.Codec RuleAbilities.RuleAbilities
codec = Fields.object $ do
  activationProhibitions <- Fields.defaulted "activationProhibitions" [] (Common.list ActivationProhibition.codec) RuleAbilities.activationProhibitions
  attachRestrictions <- Fields.defaulted "attachRestrictions" [] (Common.list AttachRestriction.codec) RuleAbilities.attachRestrictions
  attackCosts <- Fields.defaulted "attackCosts" [] (Common.list AttackCost.codec) RuleAbilities.attackCosts
  attackPermissions <- Fields.defaulted "attackPermissions" [] (Common.list AttackPermission.codec) RuleAbilities.attackPermissions
  attackRequirements <- Fields.defaulted "attackRequirements" [] (Common.list AttackRequirement.codec) RuleAbilities.attackRequirements
  blockCosts <- Fields.defaulted "blockCosts" [] (Common.list BlockCost.codec) RuleAbilities.blockCosts
  blockPermissions <- Fields.defaulted "blockPermissions" [] (Common.list BlockPermission.codec) RuleAbilities.blockPermissions
  blockRequirements <- Fields.defaulted "blockRequirements" [] (Common.list BlockRequirement.codec) RuleAbilities.blockRequirements
  combatRestrictions <- Fields.defaulted "combatRestrictions" [] (Common.list CombatRestriction.codec) RuleAbilities.combatRestrictions
  counterRestrictions <- Fields.defaulted "counterRestrictions" [] (Common.list CounterRestriction.codec) RuleAbilities.counterRestrictions
  crewRestrictions <- Fields.defaulted "crewRestrictions" [] (Common.list CrewRestriction.codec) RuleAbilities.crewRestrictions
  entryRestrictions <- Fields.defaulted "entryRestrictions" [] (Common.list EntryRestriction.codec) RuleAbilities.entryRestrictions
  sacrificeRestrictions <- Fields.defaulted "sacrificeRestrictions" [] (Common.list SacrificeRestriction.codec) RuleAbilities.sacrificeRestrictions
  targetRestrictions <- Fields.defaulted "targetRestrictions" [] (Common.list TargetRestriction.codec) RuleAbilities.targetRestrictions
  untapRestrictions <- Fields.defaulted "untapRestrictions" [] (Common.list UntapRestriction.codec) RuleAbilities.untapRestrictions
  pure
    RuleAbilities.MkRuleAbilities
      { RuleAbilities.activationProhibitions = activationProhibitions,
        RuleAbilities.attachRestrictions = attachRestrictions,
        RuleAbilities.attackCosts = attackCosts,
        RuleAbilities.attackPermissions = attackPermissions,
        RuleAbilities.attackRequirements = attackRequirements,
        RuleAbilities.blockCosts = blockCosts,
        RuleAbilities.blockPermissions = blockPermissions,
        RuleAbilities.blockRequirements = blockRequirements,
        RuleAbilities.combatRestrictions = combatRestrictions,
        RuleAbilities.counterRestrictions = counterRestrictions,
        RuleAbilities.crewRestrictions = crewRestrictions,
        RuleAbilities.entryRestrictions = entryRestrictions,
        RuleAbilities.sacrificeRestrictions = sacrificeRestrictions,
        RuleAbilities.targetRestrictions = targetRestrictions,
        RuleAbilities.untapRestrictions = untapRestrictions
      }
