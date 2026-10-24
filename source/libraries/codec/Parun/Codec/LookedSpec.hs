module Parun.Codec.LookedSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.Looked as Looked
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Looked as Looked
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Looked" $ do
  -- CR 701.20e's look, shown to a looker and the player controlling them.
  Spec.it s "MkLooked, every key" $
    Common.assertCodec
      s
      Looked.codec
      ( Looked.MkLooked
          { Looked.card = ObjectId.MkObjectId 7,
            Looked.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            Looked.audience = Set.fromList [PlayerId.MkPlayerId 0, PlayerId.MkPlayerId 1]
          }
      )
      ( "{\"card\":7,\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"audience\":[0,1]}"
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s Looked.codec
