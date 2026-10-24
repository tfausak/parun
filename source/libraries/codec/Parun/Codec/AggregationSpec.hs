module Parun.Codec.AggregationSpec where

import qualified Parun.Codec.Aggregation as Aggregation
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.DistinctOf as DistinctOf

-- Instantiated at Integer, the simplest element codec available: Aggregation is
-- parametric in the per-member quantity it reads, and no card cares which
-- concrete element type this spec exercises.
spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Aggregation" $ do
  Spec.it s "Members" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      Aggregation.Members
      " {\"type\":\"Members\"} "
  Spec.it s "Distinct" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      (Aggregation.Distinct DistinctOf.CardTypes)
      " {\"type\":\"Distinct\",\"value\":{\"type\":\"CardTypes\"}} "
  Spec.it s "MostSharingACreatureType" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      Aggregation.MostSharingACreatureType
      " {\"type\":\"MostSharingACreatureType\"} "
  Spec.it s "MostSharingACardType" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      Aggregation.MostSharingACardType
      " {\"type\":\"MostSharingACardType\"} "
  Spec.it s "DistinctNames" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      Aggregation.DistinctNames
      " {\"type\":\"DistinctNames\"} "
  Spec.it s "Greatest" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      (Aggregation.Greatest 3)
      " {\"type\":\"Greatest\",\"value\":3} "
  Spec.it s "Total" $
    Common.assertCodec
      s
      (Aggregation.codec Common.integer)
      (Aggregation.Total 3)
      " {\"type\":\"Total\",\"value\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (Aggregation.codec Common.integer)
