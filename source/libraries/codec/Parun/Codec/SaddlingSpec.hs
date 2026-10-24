module Parun.Codec.SaddlingSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.Saddling as Saddling
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Saddling as Saddling

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Saddling" $ do
  -- CR 702.171c. TWO saddlers, and neither of them the Mount: only an
  -- asymmetric case catches a codec that crossed the two sides of the relation.
  Spec.it s "MkSaddling, both keys" $
    Common.assertCodec
      s
      Saddling.codec
      ( Saddling.MkSaddling
          { Saddling.mount = ObjectId.MkObjectId 1,
            Saddling.saddledBy = Set.fromList [ObjectId.MkObjectId 2, ObjectId.MkObjectId 3]
          }
      )
      " {\"mount\":1,\"saddledBy\":[2,3]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Saddling.codec
