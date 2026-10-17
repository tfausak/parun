{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ActiveCopy where

import qualified Pawl.Codec.CopyCoverage as CopyCoverage
import qualified Pawl.Codec.Expiry as Expiry
import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.Codec.Timestamp as Timestamp
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ActiveCopy as ActiveCopy

codec :: Codec.Codec ActiveCopy.ActiveCopy
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveCopy.source
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveCopy.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveCopy.expiry
  covers <- Fields.required "covers" CopyCoverage.codec ActiveCopy.covers
  snapshot <- Fields.required "snapshot" ProjectedCharacteristics.codec ActiveCopy.snapshot
  turned <- Fields.defaulted "turned" Nothing (Common.maybe ProjectedCharacteristics.codec) ActiveCopy.turned
  pure
    ActiveCopy.MkActiveCopy
      { ActiveCopy.source = source,
        ActiveCopy.timestamp = timestamp,
        ActiveCopy.expiry = expiry,
        ActiveCopy.covers = covers,
        ActiveCopy.snapshot = snapshot,
        ActiveCopy.turned = turned
      }
