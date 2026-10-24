{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CouldProduce where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaFilter as ManaFilter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CouldProduce as CouldProduce

-- | A bare object keyed by the record's field names, both required.
codec :: Codec.Codec CouldProduce.CouldProduce
codec = Fields.object $ do
  among <- Fields.required "among" (Filter.codec Keyword.codec) CouldProduce.among
  types <- Fields.required "types" ManaFilter.codec CouldProduce.types
  pure CouldProduce.MkCouldProduce {CouldProduce.among = among, CouldProduce.types = types}
