{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Looked where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.ProjectedCharacteristics as ProjectedCharacteristics
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Looked as Looked

-- | A bare object keyed by the record's field names. Runtime-only, as
-- Parun.Codec.Revealed is.
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
