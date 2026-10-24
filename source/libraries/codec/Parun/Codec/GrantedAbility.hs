module Parun.Codec.GrantedAbility where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ActivatedAbility as ActivatedAbility
import qualified Parun.Codec.AlternativeCost as AlternativeCost
import qualified Parun.Codec.CostReduction as CostReduction
import qualified Parun.Codec.Effect as Effect
import qualified Parun.Codec.PlayerStaticAbility as PlayerStaticAbility
import qualified Parun.Codec.PrintedReplacement as PrintedReplacement
import qualified Parun.Codec.RuleAbilities as RuleAbilities
import qualified Parun.Codec.SpendManaAsThough as SpendManaAsThough
import qualified Parun.Codec.StaticAbility as StaticAbility
import qualified Parun.Codec.TriggeredAbility as TriggeredAbility
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.GrantedAbility as GrantedAbility

-- | The quoted ability a CR 613.1f grant carries, tagged by CR 113.3's ability
-- kind. Nested inside the modification's own @value@ rather than spelled as two
-- modification tags, because Parun.Codec.Modification is parametric in exactly
-- this type and cannot name either ability codec.
--
-- RECURSIVE: 'codec' passes itself down as the ability codec, which is the knot
-- Parun.Types.GrantedAbility ties in the type. It terminates for
-- Parun.Codec.Card's reason -- 'Arm.tagged' registers this type's name before
-- running the schema body, so the re-entry emits a @$ref@.
codec :: (Typeable.Typeable card, Eq card) => Codec.Codec card -> Codec.Codec (GrantedAbility.GrantedAbility card)
codec cardCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "Activated" (ActivatedAbility.codec cardCodec (codec cardCodec)) GrantedAbility.Activated (\x -> case x of GrantedAbility.Activated y -> Just y; _ -> Nothing),
      Arm.payload "Triggered" (TriggeredAbility.codec cardCodec (codec cardCodec)) GrantedAbility.Triggered (\x -> case x of GrantedAbility.Triggered y -> Just y; _ -> Nothing),
      Arm.payload "Static" (StaticAbility.codec (codec cardCodec)) GrantedAbility.Static (\x -> case x of GrantedAbility.Static y -> Just y; _ -> Nothing),
      Arm.payload "Rules" RuleAbilities.codec GrantedAbility.Rules (\x -> case x of GrantedAbility.Rules y -> Just y; _ -> Nothing),
      Arm.payload "Replacement" (PrintedReplacement.codec cardCodec (codec cardCodec) (Effect.codec cardCodec (codec cardCodec))) GrantedAbility.Replacement (\x -> case x of GrantedAbility.Replacement y -> Just y; _ -> Nothing),
      Arm.payload "Player" PlayerStaticAbility.codec GrantedAbility.Player (\x -> case x of GrantedAbility.Player y -> Just y; _ -> Nothing),
      Arm.payload "SelfCostReduction" CostReduction.codec GrantedAbility.SelfCostReduction (\x -> case x of GrantedAbility.SelfCostReduction y -> Just y; _ -> Nothing),
      Arm.payload "SelfAlternativeCost" AlternativeCost.codec GrantedAbility.SelfAlternativeCost (\x -> case x of GrantedAbility.SelfAlternativeCost y -> Just y; _ -> Nothing),
      Arm.payload "SelfSpendManaAsThough" SpendManaAsThough.codec GrantedAbility.SelfSpendManaAsThough (\x -> case x of GrantedAbility.SelfSpendManaAsThough y -> Just y; _ -> Nothing)
    ]

tagOf :: GrantedAbility.GrantedAbility card -> String
tagOf x = case x of
  GrantedAbility.Activated {} -> "Activated"
  GrantedAbility.Triggered {} -> "Triggered"
  GrantedAbility.Static {} -> "Static"
  GrantedAbility.Rules {} -> "Rules"
  GrantedAbility.Replacement {} -> "Replacement"
  GrantedAbility.Player {} -> "Player"
  GrantedAbility.SelfCostReduction {} -> "SelfCostReduction"
  GrantedAbility.SelfAlternativeCost {} -> "SelfAlternativeCost"
  GrantedAbility.SelfSpendManaAsThough {} -> "SelfSpendManaAsThough"
