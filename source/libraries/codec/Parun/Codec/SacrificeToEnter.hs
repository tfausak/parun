{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SacrificeToEnter where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SacrificeToEnter as SacrificeToEnter

codec :: Codec.Codec SacrificeToEnter.SacrificeToEnter
codec = Fields.object $ do
  count <- Fields.required "count" Common.natural SacrificeToEnter.count
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) SacrificeToEnter.filter
  pure
    SacrificeToEnter.MkSacrificeToEnter
      { SacrificeToEnter.count = count,
        SacrificeToEnter.filter = filter_
      }
