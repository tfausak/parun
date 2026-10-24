{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AnyNumberMatching where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AnyNumberMatching as AnyNumberMatching

-- | The ceiling is ELIDED when absent, so "any number" writes no key.
codec :: Codec.Codec AnyNumberMatching.AnyNumberMatching
codec = Fields.object $ do
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) AnyNumberMatching.filter
  atMost <- Fields.defaulted "atMost" Nothing (Common.maybe Quantity.codec) AnyNumberMatching.atMost
  pure
    AnyNumberMatching.MkAnyNumberMatching
      { AnyNumberMatching.filter = filter_,
        AnyNumberMatching.atMost = atMost
      }
