module Parun.Codec.ObjectSnapshotSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ObjectSnapshot as ObjectSnapshot
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ObjectSnapshot" $ do
  -- Controller and owner differ, so an encoder writing one for the other fails.
  Spec.it s "a controlled object" $
    Common.assertCodec
      s
      ObjectSnapshot.codec
      ObjectSnapshot.MkObjectSnapshot
        { ObjectSnapshot.object = ObjectId.MkObjectId 9,
          ObjectSnapshot.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
          ObjectSnapshot.controller = Just (PlayerId.MkPlayerId 1),
          ObjectSnapshot.owner = PlayerId.MkPlayerId 2,
          ObjectSnapshot.zone = Zone.Battlefield,
          ObjectSnapshot.home = Zone.Command,
          ObjectSnapshot.lapsedGrants = Set.empty
        }
      (" {\"object\":9,\"characteristics\":" <> ProjectedCharacteristicsSpec.testCharacteristicsJson <> ",\"controller\":1,\"owner\":2,\"zone\":{\"type\":\"Battlefield\"},\"home\":{\"type\":\"Command\"}} ")
  -- CR 108.4: a card in a hand has no controller.
  Spec.it s "an object with no controller" $
    Common.assertCodec
      s
      ObjectSnapshot.codec
      ObjectSnapshot.MkObjectSnapshot
        { ObjectSnapshot.object = ObjectId.MkObjectId 3,
          ObjectSnapshot.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
          ObjectSnapshot.controller = Nothing,
          ObjectSnapshot.owner = PlayerId.MkPlayerId 4,
          ObjectSnapshot.zone = Zone.Hand,
          ObjectSnapshot.home = Zone.Battlefield,
          ObjectSnapshot.lapsedGrants = Set.empty
        }
      (" {\"object\":3,\"characteristics\":" <> ProjectedCharacteristicsSpec.testCharacteristicsJson <> ",\"controller\":null,\"owner\":4,\"zone\":{\"type\":\"Hand\"}} ")
  Spec.it s "has a schema" $
    Common.assertHasSchema s ObjectSnapshot.codec
