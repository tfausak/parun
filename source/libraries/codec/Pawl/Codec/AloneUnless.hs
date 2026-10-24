{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.AloneUnless where

import qualified Pawl.Codec.AbilityName as AbilityName
import qualified Pawl.Codec.Affected as Affected
import qualified Pawl.Codec.Condition as Condition
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.AloneUnless as AloneUnless

-- | Pawl.Codec.AffectedUnless's shape, plus "alongside", which DEFAULTS to
-- Nothing: a plain "can't attack alone" (Bonded Construct) writes no key.
codec :: Codec.Codec AloneUnless.AloneUnless
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec AloneUnless.affected
  alongside <- Fields.defaulted "alongside" Nothing (Common.maybe (Filter.codec Keyword.codec)) AloneUnless.alongside
  unless <- Fields.defaulted "unless" Nothing (Common.maybe Condition.codec) AloneUnless.unless
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityName.codec) AloneUnless.name
  pure
    AloneUnless.MkAloneUnless
      { AloneUnless.affected = affected,
        AloneUnless.alongside = alongside,
        AloneUnless.unless = unless,
        AloneUnless.name = name
      }
