module Parun.Codec.CopyCoverageSpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Codec.CopyCoverage as CopyCoverage
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CopyCoverage as CopyCoverage
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CopyCoverage" $ do
  Spec.it s "These" $
    Common.assertCodec
      s
      CopyCoverage.codec
      (CopyCoverage.These (Set.fromList [ObjectId.MkObjectId 3, ObjectId.MkObjectId 4]))
      " {\"type\":\"These\",\"value\":[3,4]} "
  Spec.it s "SourceHost" $
    Common.assertCodec
      s
      CopyCoverage.codec
      (CopyCoverage.SourceHost (Map.singleton (ObjectId.MkObjectId 3) (Timestamp.MkTimestamp 7)))
      " {\"type\":\"SourceHost\",\"value\":{\"3\":7}} "
  Spec.it s "Attachment" $
    Common.assertCodec
      s
      CopyCoverage.codec
      (CopyCoverage.Attachment (ObjectId.MkObjectId 3))
      " {\"type\":\"Attachment\",\"value\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CopyCoverage.codec
