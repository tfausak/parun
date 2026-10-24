{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Transformed where

import qualified Data.Set as Set
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Transformed as Transformed

-- | Parun.Codec.HalfUnlocked's shape: a bare object keyed by the record's field
-- names. Runtime-only, GameEvent serialising transcripts rather than card data.
codec :: Codec.Codec Transformed.Transformed
codec = Fields.object $ do
  object <- Fields.required "object" ObjectId.codec Transformed.object
  characteristics <- Fields.required "characteristics" ProjectedCharacteristics.codec Transformed.characteristics
  controller <- Fields.defaulted "controller" Nothing (Common.maybe PlayerId.codec) Transformed.controller
  attachments <- Fields.defaulted "attachments" Set.empty (Common.set ObjectId.codec) Transformed.attachments
  lapsedGrants <- Fields.defaulted "lapsedGrants" Set.empty (Common.set Condition.codec) Transformed.lapsedGrants
  pure
    Transformed.MkTransformed
      { Transformed.object = object,
        Transformed.characteristics = characteristics,
        Transformed.controller = controller,
        Transformed.attachments = attachments,
        Transformed.lapsedGrants = lapsedGrants
      }
