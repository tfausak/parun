{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Looked where

import qualified Pawl.Codec.ObjectId as ObjectId
import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Looked as Looked

-- | A bare object keyed by the record's field names. Runtime-only, as
-- Pawl.Codec.Revealed is.
codec :: Codec.Codec Looked.Looked
codec = Fields.object $ do
  card <- Fields.required "card" ObjectId.codec Looked.card
  characteristics <- Fields.required "characteristics" ProjectedCharacteristics.codec Looked.characteristics
  audience <- Fields.required "audience" (Common.set PlayerId.codec) Looked.audience
  pure
    Looked.MkLooked
      { Looked.card = card,
        Looked.characteristics = characteristics,
        Looked.audience = audience
      }
