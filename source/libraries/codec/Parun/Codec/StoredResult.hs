{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.StoredResult where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.StoredResult as StoredResult

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec StoredResult.StoredResult
codec = Fields.object $ do
  sides <- Fields.required "sides" Common.natural StoredResult.sides
  value <- Fields.required "value" Common.natural StoredResult.value
  pure StoredResult.MkStoredResult {StoredResult.sides = sides, StoredResult.value = value}
