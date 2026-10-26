module Parun.Codec.AttackRequirementSpec where

import qualified Parun.Codec.AttackRequirement as AttackRequirement
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.AttackRequirement as AttackRequirement
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.RequiredDefender as RequiredDefender
import qualified Parun.Types.RequirementArity as RequirementArity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackRequirement" $ do
  -- Curse of the Nightly Hunt's shape (CR 303.4m read through the enchanted
  -- player): AttachedPlayerControls, unlike BlockRequirement's Attached/Matching
  -- pair, since an attacking requirement's subject can be a whole controlled set.
  Spec.it s "MkAttackRequirement" $
    Common.assertCodec
      s
      AttackRequirement.codec
      (AttackRequirement.MkAttackRequirement (Affected.AttachedPlayerControls (Filter.HasCardType CardType.Creature)) Nothing Nothing RequirementArity.EachSubject)
      " {\"subject\":{\"type\":\"AttachedPlayerControls\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Otarian Juggernaut's shape: CR 508.1d's second reading, "or that it attacks
  -- if some condition is met", written as CR 604.2's "as long as" clause over
  -- the cards in the controller's graveyard.
  Spec.it s "a gated requirement" $
    Common.assertCodec
      s
      AttackRequirement.codec
      ( AttackRequirement.MkAttackRequirement
          (Affected.Matching Filter.IsSource)
          Nothing
          ( Just
              ( Condition.Compares
                  ( Compares.MkCompares
                      ( Quantity.Count
                          Count.MkCount
                            { Count.scope = Scope.InZone (InZone.MkInZone Zone.Graveyard (PlayerRef.Relative PlayerRelation.You)),
                              Count.filter = Filter.And [],
                              Count.aggregation = Aggregation.Members
                            }
                      )
                      Comparison.AtLeast
                      (Quantity.Literal 7)
                  )
              )
          )
          RequirementArity.EachSubject
      )
      " {\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"while\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Count\",\"value\":{\"aggregation\":{\"type\":\"Members\"},\"filter\":{\"type\":\"And\",\"value\":[]},\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Graveyard\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}}}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":7}}}} "
  -- Public Enemy's shape: CR 508.1d's OBJECT axis, which
  -- Parun.Types.ActiveAttackRequirement used to be the only carrier of.
  Spec.it s "a requirement naming whom to attack" $
    Common.assertCodec
      s
      AttackRequirement.codec
      ( AttackRequirement.MkAttackRequirement
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          (Just RequiredDefender.ControllerOfAttached)
          Nothing
          RequirementArity.EachSubject
      )
      " {\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"object\":{\"type\":\"ControllerOfAttached\"}} "
  -- Seeker of Slaanesh's shape: CR 508.1d read as ONE requirement over every
  -- creature an opponent controls, obeyed by attacking with any one of them.
  Spec.it s "a group requirement" $
    Common.assertCodec
      s
      AttackRequirement.codec
      ( AttackRequirement.MkAttackRequirement
          (Affected.Matching (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.Opponent]))
          Nothing
          Nothing
          RequirementArity.AnySubject
      )
      " {\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"Opponent\"}}}]}},\"arity\":{\"type\":\"AnySubject\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackRequirement.codec
