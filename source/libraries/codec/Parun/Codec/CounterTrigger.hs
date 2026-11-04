{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterTrigger where

import qualified Parun.Codec.CounterGrouping as CounterGrouping
import qualified Parun.Codec.CounterHolder as CounterHolder
import qualified Parun.Codec.CounterKind as CounterKind
import qualified Parun.Codec.CounterMotion as CounterMotion
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterGrouping as CounterGroupingType
import qualified Parun.Types.CounterHolder as CounterHolderType
import qualified Parun.Types.CounterTrigger as CounterTrigger

-- | A bare object keyed by the record's field names. Self, no threshold and
-- EachPermanent write no key.
codec :: Codec.Codec CounterTrigger.CounterTrigger
codec = Fields.object $ do
  kind <- Fields.required "kind" (CounterKind.codec Keyword.codec) CounterTrigger.kind
  motion <- Fields.required "motion" CounterMotion.codec CounterTrigger.motion
  holder <- Fields.defaulted "holder" CounterHolderType.Self CounterHolder.codec CounterTrigger.holder
  threshold <- Fields.defaulted "threshold" Nothing (Common.maybe Common.natural) CounterTrigger.threshold
  grouping <- Fields.defaulted "grouping" CounterGroupingType.EachPermanent CounterGrouping.codec CounterTrigger.grouping
  pure
    CounterTrigger.MkCounterTrigger
      { CounterTrigger.kind = kind,
        CounterTrigger.motion = motion,
        CounterTrigger.holder = holder,
        CounterTrigger.threshold = threshold,
        CounterTrigger.grouping = grouping
      }
