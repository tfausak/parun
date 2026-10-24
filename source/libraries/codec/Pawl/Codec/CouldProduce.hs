{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.CouldProduce where

import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.ManaFilter as ManaFilter
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.CouldProduce as CouldProduce

-- | A bare object keyed by the record's field names, both required.
codec :: Codec.Codec CouldProduce.CouldProduce
codec = Fields.object $ do
  among <- Fields.required "among" (Filter.codec Keyword.codec) CouldProduce.among
  types <- Fields.required "types" ManaFilter.codec CouldProduce.types
  pure CouldProduce.MkCouldProduce {CouldProduce.among = among, CouldProduce.types = types}
