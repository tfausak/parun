-- Covers Parun.Codec.BlockCost. Parun.Codec.PerCreature, the one codec it
-- dispatches to that Parun.Codec.Affected does not, is round-tripped through
-- Parun.Codec.AttackCostSpec as well: one share type serves both combat costs, so
-- what is proved here is this object's own three keys.
module Parun.Codec.BlockCostSpec where

import qualified Parun.Codec.BlockCost as BlockCost
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.BlockCost as BlockCost
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PerCreature as PerCreature
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockCost" $ do
  -- Oppressive Rays: the subject is what the Aura is attached to, and the cost is
  -- ONE blocker's share (CR 509.1d totals them).
  Spec.it s "MkBlockCost" $
    Common.assertCodec
      s
      BlockCost.codec
      ( BlockCost.MkBlockCost
          Affected.Attached
          (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 3])) []))
          Nothing
          Nothing
      )
      " {\"perBlocker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":3}]}},\"subject\":{\"type\":\"Attached\"}} "
  -- Hipparion: only blocks of attackers with power 3 or greater cost {1}.
  Spec.it s "MkBlockCost with attackers" $
    Common.assertCodec
      s
      BlockCost.codec
      ( BlockCost.MkBlockCost
          (Affected.Matching Filter.IsSource)
          (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []))
          (Just (Filter.Measures (Measures.MkMeasures Measure.Power Comparison.AtLeast (Operand.Literal 3))))
          Nothing
      )
      " {\"attackers\":{\"type\":\"Measures\",\"value\":{\"measure\":{\"type\":\"Power\"},\"comparison\":{\"type\":\"AtLeast\"},\"operand\":{\"type\":\"Literal\",\"value\":3}}},\"perBlocker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}},\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  -- Archangel of Tithes: CR 611.3a's "as long as this creature is attacking".
  Spec.it s "MkBlockCost with a while" $
    Common.assertCodec
      s
      BlockCost.codec
      ( BlockCost.MkBlockCost
          (Affected.Matching (Filter.HasCardType CardType.Creature))
          (PerCreature.Fixed (Cost.MkCost (Just (ManaCost.MkManaCost [ManaSymbol.Generic 1])) []))
          Nothing
          ( Just
              ( Condition.Compares
                  ( Compares.MkCompares
                      ( Quantity.Count
                          ( Count.MkCount
                              (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
                              (Filter.And [Filter.IsSource, Filter.IsAttacking])
                              Aggregation.Members
                          )
                      )
                      Comparison.AtLeast
                      (Quantity.Literal 1)
                  )
              )
          )
      )
      " {\"perBlocker\":{\"type\":\"Fixed\",\"value\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]}},\"subject\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"while\":{\"type\":\"Compares\",\"value\":{\"comparison\":{\"type\":\"AtLeast\"},\"measured\":{\"type\":\"Count\",\"value\":{\"aggregation\":{\"type\":\"Members\"},\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"IsSource\"},{\"type\":\"IsAttacking\"}]},\"scope\":{\"type\":\"InZone\",\"value\":{\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}},\"zone\":{\"type\":\"Battlefield\"}}}}},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockCost.codec
