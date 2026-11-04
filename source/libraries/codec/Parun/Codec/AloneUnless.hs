{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AloneUnless where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.CompanyCount as CompanyCount
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AloneUnless as AloneUnless
import qualified Parun.Types.CompanyCount as CompanyCount

-- | Parun.Codec.AffectedUnless's shape, plus "alongside" and "others", which
-- default to Nothing and one other: a plain "can't attack alone" (Bonded
-- Construct) writes neither key.
codec :: Codec.Codec AloneUnless.AloneUnless
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec AloneUnless.affected
  alongside <- Fields.defaulted "alongside" Nothing (Common.maybe (Filter.codec Keyword.codec)) AloneUnless.alongside
  others <- Fields.defaulted "others" (CompanyCount.AtLeastOthers 1) CompanyCount.codec AloneUnless.others
  unless <- Fields.defaulted "unless" Nothing (Common.maybe Condition.codec) AloneUnless.unless
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityName.codec) AloneUnless.name
  pure
    AloneUnless.MkAloneUnless
      { AloneUnless.affected = affected,
        AloneUnless.alongside = alongside,
        AloneUnless.others = others,
        AloneUnless.unless = unless,
        AloneUnless.name = name
      }
