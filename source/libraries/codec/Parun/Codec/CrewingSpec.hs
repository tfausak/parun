module Parun.Codec.CrewingSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.Crewing as Crewing
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Crewing as Crewing
import qualified Parun.Types.ObjectId as ObjectId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Crewing" $ do
  -- CR 702.122b/c. TWO crewers, and neither of them the Vehicle: only an
  -- asymmetric case catches a codec that crossed the two sides of the relation.
  Spec.it s "MkCrewing, both keys" $
    Common.assertCodec
      s
      Crewing.codec
      ( Crewing.MkCrewing
          { Crewing.vehicle = ObjectId.MkObjectId 1,
            Crewing.crewedBy = Set.fromList [ObjectId.MkObjectId 2, ObjectId.MkObjectId 3]
          }
      )
      " {\"crewedBy\":[2,3],\"vehicle\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Crewing.codec
