-- Covers Parun.Codec.AttackCost and the two codecs only it dispatches to,
-- Parun.Codec.AttackCostScope and Parun.Codec.PerCreature. They share a spec
-- rather than taking one each because neither is reachable on the wire except
-- through the object below, so the pair of round trips here is the whole of
-- what a card can say.
module Parun.Codec.AttackCostSpec where

import qualified Parun.Codec.AttackCost as AttackCost
import qualified Parun.Codec.AttackCostScope as AttackCostScope
import qualified Parun.Codec.PerCreature as PerCreature
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.AttackCost as AttackCost
import qualified Parun.Types.AttackCostScope as AttackCostScope
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.CostComponent as CostComponent
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ObjectCount as ObjectCount
import qualified Parun.Types.PerCreature as PerCreature
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Sacrifice as Sacrifice
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackCost" $ do
  -- The subject is every creature, since only a creature can be declared as an
  -- attacker, and the cost is ONE attacker's share (CR 508.1h totals them).
  Spec.it s "MkAttackCost" $
    Common.assertCodec
      s
      AttackCost.codec
      ( AttackCost.MkAttackCost
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])) []))
          AttackCostScope.Controller
          Nothing
      )
      " {\"perAttacker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":2}]}},\"scope\":{\"type\":\"Controller\"},\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Sphere of Safety's half of the type: the wide scope and a counted share, the
  -- two arms Ghostly Prison's literal above does not reach.
  Spec.it s "MkAttackCost with a counted share and the wider scope" $
    Common.assertCodec
      s
      AttackCost.codec
      ( AttackCost.MkAttackCost
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          ( PerCreature.Counted
              ( Quantity.Count
                  ( Count.MkCount
                      (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
                      (Filter.And [Filter.HasCardType CardType.Enchantment, Filter.HeldBy Holder.Controller PlayerRelation.You])
                      Aggregation.Members
                  )
              )
          )
          AttackCostScope.ControllerAndPlaneswalkers
          Nothing
      )
      " {\"perAttacker\":{\"type\":\"Counted\",\"value\":{\"type\":\"Count\",\"value\":{\"aggregation\":{\"type\":\"Members\"},\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Enchantment\"}},{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}]},\"scope\":{\"type\":\"InZone\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"zone\":{\"type\":\"Battlefield\"}}}}}},\"scope\":{\"type\":\"ControllerAndPlaneswalkers\"},\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  -- Exalted Dragon's half: a share with no mana and a component, which is CR
  -- 508.1h's list past "paying mana". The subject is the Dragon itself.
  Spec.it s "MkAttackCost with a non-mana share" $
    Common.assertCodec
      s
      AttackCost.codec
      ( AttackCost.MkAttackCost
          (Affected.Matching Filter.IsSource)
          ( PerCreature.Fixed
              ( Cost.MkCost
                  (Just (ManaCost.MkManaCost []))
                  [CostComponent.Sacrifice (Sacrifice.MkSacrifice (ObjectCount.Exactly (CostAmount.Fixed 1)) (Filter.HasCardType CardType.Land))]
              )
          )
          AttackCostScope.EveryAttack
          Nothing
      )
      " {\"perAttacker\":{\"type\":\"Fixed\",\"value\":{\"components\":[{\"type\":\"Sacrifice\",\"value\":{\"count\":{\"type\":\"Fixed\",\"value\":1},\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}}}],\"mana\":[]}},\"scope\":{\"type\":\"EveryAttack\"},\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  -- Exhaustive where the two literals above are representative: Arm.enum derives
  -- the scope's arm list from the type, so this is what would catch an arm the
  -- derivation missed or two that encode alike.
  Spec.it s "the scope round trips every constructor" $ Common.assertEnumCodec s AttackCostScope.codec
  -- Archangel of Tithes: CR 611.3a's "as long as this creature is untapped".
  Spec.it s "MkAttackCost with a while" $
    Common.assertCodec
      s
      AttackCost.codec
      ( AttackCost.MkAttackCost
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []))
          AttackCostScope.ControllerAndPlaneswalkers
          ( Just
              ( Condition.Compares
                  ( Compares.MkCompares
                      ( Quantity.Count
                          ( Count.MkCount
                              (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
                              (Filter.And [Filter.IsSource, Filter.Not Filter.IsTapped])
                              Aggregation.Members
                          )
                      )
                      Comparison.AtLeast
                      (Quantity.Literal 1)
                  )
              )
          )
      )
      " {\"perAttacker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}},\"scope\":{\"type\":\"ControllerAndPlaneswalkers\"},\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"while\":{\"type\":\"Compares\",\"value\":{\"comparison\":{\"type\":\"AtLeast\"},\"measured\":{\"type\":\"Count\",\"value\":{\"aggregation\":{\"type\":\"Members\"},\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"IsSource\"},{\"type\":\"Not\",\"value\":{\"type\":\"IsTapped\"}}]},\"scope\":{\"type\":\"InZone\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"zone\":{\"type\":\"Battlefield\"}}}}},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackCost.codec
  Spec.it s "the scope has a schema" $ Common.assertHasSchema s AttackCostScope.codec
  Spec.it s "the share has a schema" $ Common.assertHasSchema s PerCreature.codec
