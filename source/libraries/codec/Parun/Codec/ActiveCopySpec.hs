module Parun.Codec.ActiveCopySpec where

import qualified Data.Map.Strict as Map
import qualified Data.Set as Set
import qualified Parun.Codec.ActiveCopy as ActiveCopy
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveCopy as ActiveCopy
import qualified Parun.Types.CopyCoverage as CopyCoverage
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveCopy" $ do
  -- Mirrorweave's row, over two subjects. `source` and the two subjects are all
  -- distinct ObjectIds, so a swap cannot pass; "until end of turn" arms CR
  -- 514.2's AtCleanup. The snapshot is the all-default fixture next door, which
  -- keeps this spec about the row's own keys.
  Spec.it s "two permanents copying one original until end of turn" $
    Common.assertCodec
      s
      ActiveCopy.codec
      ActiveCopy.MkActiveCopy
        { ActiveCopy.source = ObjectId.MkObjectId 1,
          ActiveCopy.timestamp = Timestamp.MkTimestamp 2,
          ActiveCopy.expiry = Expiry.AtCleanup,
          ActiveCopy.covers = CopyCoverage.These (Set.fromList [ObjectId.MkObjectId 3, ObjectId.MkObjectId 4]),
          ActiveCopy.snapshot = ProjectedCharacteristicsSpec.minimalCharacteristics,
          ActiveCopy.turned = Nothing
        }
      " {\"source\":1,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"covers\":{\"type\":\"These\",\"value\":[3,4]},\"snapshot\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]}} "
  -- CR 730.2i: a merge applied over the row, with its turned-over reading.
  Spec.it s "a merged permanent's row with its turned reading" $
    Common.assertCodec
      s
      ActiveCopy.codec
      ActiveCopy.MkActiveCopy
        { ActiveCopy.source = ObjectId.MkObjectId 1,
          ActiveCopy.timestamp = Timestamp.MkTimestamp 2,
          ActiveCopy.expiry = Expiry.AtCleanup,
          ActiveCopy.covers = CopyCoverage.These (Set.singleton (ObjectId.MkObjectId 3)),
          ActiveCopy.snapshot = ProjectedCharacteristicsSpec.minimalCharacteristics,
          ActiveCopy.turned = Just ProjectedCharacteristicsSpec.minimalCharacteristics
        }
      " {\"source\":1,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"covers\":{\"type\":\"These\",\"value\":[3]},\"snapshot\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]},\"turned\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]}} "
  -- Metamorphic Alteration's row, following its source's host, one object of
  -- which a later copy effect took over while the source had timestamp 5.
  Spec.it s "a row following its source's host" $
    Common.assertCodec
      s
      ActiveCopy.codec
      ActiveCopy.MkActiveCopy
        { ActiveCopy.source = ObjectId.MkObjectId 1,
          ActiveCopy.timestamp = Timestamp.MkTimestamp 2,
          ActiveCopy.expiry = Expiry.AtCleanup,
          ActiveCopy.covers = CopyCoverage.SourceHost (Map.singleton (ObjectId.MkObjectId 3) (Timestamp.MkTimestamp 5)),
          ActiveCopy.snapshot = ProjectedCharacteristicsSpec.minimalCharacteristics,
          ActiveCopy.turned = Nothing
        }
      " {\"source\":1,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"covers\":{\"type\":\"SourceHost\",\"value\":{\"3\":5}},\"snapshot\":{\"names\":[\"Mountain\"],\"cardTypes\":[{\"type\":\"Land\"}]}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveCopy.codec
