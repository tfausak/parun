{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SacrificeAnyNumber where

import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SacrificeAnyNumber as SacrificeAnyNumber

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec SacrificeAnyNumber.SacrificeAnyNumber
codec = Fields.object $ do
  each <- Fields.required "each" Quantity.codec SacrificeAnyNumber.each
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) SacrificeAnyNumber.filter
  kind <- Fields.required "kind" (Common.maybe (CounterKind.codec Keyword.codec)) SacrificeAnyNumber.kind
  pure
    SacrificeAnyNumber.MkSacrificeAnyNumber
      { SacrificeAnyNumber.each = each,
        SacrificeAnyNumber.filter = filter_,
        SacrificeAnyNumber.kind = kind
      }
