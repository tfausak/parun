{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveCopy where

import qualified Parun.Codec.CopyCoverage as CopyCoverage
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveCopy as ActiveCopy

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
