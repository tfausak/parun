{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AffectedUnless where

import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.Affected as Affected
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AffectedUnless as AffectedUnless

-- | The bare object the enclosing tag already carried, now with a record behind
-- it to name.
--
-- "name" DEFAULTS to Nothing, which is what all but one printing writes: CR
-- 116.2d's permission is rare, so a restriction that grants none names no
-- ability for one to refer to. "amount" defaults the same way: almost no
-- restriction compares against a computed number.
codec :: Codec.Codec AffectedUnless.AffectedUnless
codec = Fields.object $ do
  affected <- Fields.required "affected" Affected.codec AffectedUnless.affected
  unless <- Fields.defaulted "unless" Nothing (Common.maybe Condition.codec) AffectedUnless.unless
  name <- Fields.defaulted "name" Nothing (Common.maybe AbilityName.codec) AffectedUnless.name
  amount <- Fields.defaulted "amount" Nothing (Common.maybe Quantity.codec) AffectedUnless.amount
  pure
    AffectedUnless.MkAffectedUnless
      { AffectedUnless.affected = affected,
        AffectedUnless.unless = unless,
        AffectedUnless.name = name,
        AffectedUnless.amount = amount
      }
