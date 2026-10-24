module Parun.Codec.CountSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Count as Count
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Count as Count
import qualified Parun.Types.DistinctOf as DistinctOf
import qualified Parun.Types.EventShape as EventShape
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.MovedBetween as MovedBetween
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Zone as Zone

-- Instantiated at Integer, the simplest element codec available: MkCount is
-- parametric in the per-object quantity its Aggregation reads, and no case
-- below exercises Aggregation.Greatest, the one arm that would need it.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Count" $ do
  Spec.it s "MkCount, in a zone" $
    Common.assertCodec
      s
      (Count.codec Common.integer)
      ( Count.MkCount
          (Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)))
          (Filter.And [Filter.HasSubtype Subtype.Swamp, Filter.ControlledBy PlayerRelation.You])
          Aggregation.Members
      )
      " {\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}},\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Swamp\"}},{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}}]},\"aggregation\":{\"type\":\"Members\"}} "
  -- CR 608.2i's look-back-in-time domain.
  Spec.it s "MkCount, scoped to the event history" $
    Common.assertCodec
      s
      (Count.codec Common.integer)
      ( Count.MkCount
          (Scope.InHistory (EventShape.MovedBetween (MovedBetween.MkMovedBetween Zone.Battlefield Zone.Graveyard)))
          (Filter.HasCardType CardType.Creature)
          (Aggregation.Distinct DistinctOf.CardTypes)
      )
      " {\"scope\":{\"type\":\"InHistory\",\"value\":{\"type\":\"MovedBetween\",\"value\":{\"from\":{\"type\":\"Battlefield\"},\"to\":{\"type\":\"Graveyard\"}}}},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"aggregation\":{\"type\":\"Distinct\",\"value\":{\"type\":\"CardTypes\"}}} "
  Spec.it s "MkCount, scoped to a slot" $
    Common.assertCodec
      s
      (Count.codec Common.integer)
      ( Count.MkCount
          (Scope.InZone (InZone.MkInZone Zone.Hand (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")))))
          (Filter.And [])
          Aggregation.Members
      )
      " {\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Hand\"},\"player\":{\"type\":\"InSlot\",\"value\":\"target\"}}},\"filter\":{\"type\":\"And\",\"value\":[]},\"aggregation\":{\"type\":\"Members\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (Count.codec Common.integer)
