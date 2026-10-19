module Pawl.Codec.ObjectViewSpec where

import qualified Data.Map.Strict as Map
import qualified Pawl.Codec.ObjectView as ObjectView
import qualified Pawl.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.ObjectView as ObjectView
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.TapState as TapState

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ObjectView" $ do
  Spec.it s "a seen object" $
    Common.assertCodec
      s
      ObjectView.codec
      (hidden {ObjectView.characteristics = Just ProjectedCharacteristicsSpec.testCharacteristics})
      ( "{\"object\":7,\"owner\":0,\"controller\":1,\"tapped\":true,\"damage\":2,\"counters\":[],\"attachedTo\":null,\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"face\":null}"
      )
  Spec.it s "a hidden object" $
    Common.assertCodec
      s
      ObjectView.codec
      hidden
      "{\"object\":7,\"owner\":0,\"controller\":1,\"tapped\":true,\"damage\":2,\"counters\":[],\"attachedTo\":null,\"characteristics\":null,\"face\":null}"
  Spec.it s "a face-down object its seat may look at" $
    Common.assertCodec
      s
      ObjectView.codec
      (hidden {ObjectView.face = Just ProjectedCharacteristicsSpec.testCharacteristics})
      ( "{\"object\":7,\"owner\":0,\"controller\":1,\"tapped\":true,\"damage\":2,\"counters\":[],\"attachedTo\":null,\"characteristics\":null,\"face\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> "}"
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s ObjectView.codec

-- Tapped and damaged, so neither status key encodes a default.
hidden :: ObjectView.ObjectView
hidden =
  ObjectView.MkObjectView
    { ObjectView.object = ObjectId.MkObjectId 7,
      ObjectView.owner = PlayerId.MkPlayerId 0,
      ObjectView.controller = Just (PlayerId.MkPlayerId 1),
      ObjectView.tapped = TapState.Tapped,
      ObjectView.damage = 2,
      ObjectView.counters = Map.empty,
      ObjectView.attachedTo = Nothing,
      ObjectView.characteristics = Nothing,
      ObjectView.face = Nothing
    }
