{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.LimitUnless where

import qualified Pawl.Codec.Affected as Affected
import qualified Pawl.Codec.Comparison as Comparison
import qualified Pawl.Codec.Condition as Condition
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Comparison as Comparison.Type
import qualified Pawl.Types.LimitUnless as LimitUnless

-- | The bare object the enclosing tag already carried, now with a record behind
-- it to name. "limit" and not "affected", because a bound names no blocker: the
-- key set is what tells a reader of the card file which shape it is looking at
-- without consulting the tag.
--
-- "comparison" defaults to AtMost, the "no more than" every bound wrote before
-- Phyrexian Colossus' "three or more".
--
-- "attackers" defaults to absent, which is the WHOLE declaration: Silent
-- Arbiter writes no such key, and Charging Rhino does.
codec :: Codec.Codec LimitUnless.LimitUnless
codec = Fields.object $ do
  limit <- Fields.required "limit" Common.natural LimitUnless.limit
  comparison <- Fields.defaulted "comparison" Comparison.Type.AtMost Comparison.codec LimitUnless.comparison
  attackers <- Fields.defaulted "attackers" Nothing (Common.maybe Affected.codec) LimitUnless.attackers
  unless <- Fields.defaulted "unless" Nothing (Common.maybe Condition.codec) LimitUnless.unless
  pure
    LimitUnless.MkLimitUnless
      { LimitUnless.limit = limit,
        LimitUnless.comparison = comparison,
        LimitUnless.attackers = attackers,
        LimitUnless.unless = unless
      }
