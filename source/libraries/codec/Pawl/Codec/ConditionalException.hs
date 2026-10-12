{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ConditionalException where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.Condition as Condition
import qualified Pawl.Codec.CopyException as CopyException
import qualified Pawl.Codec.WithCounters as WithCounters
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ConditionalException as ConditionalException

-- | A bare object keyed by the record's field names. @exceptions@ and
-- @counters@ are defaulted as Pawl.Codec.AsCopy's same-named keys are: Spark
-- Double's parts state counters alone, Vizier of Many Faces' exceptions alone.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (ConditionalException.ConditionalException ability)
codec abilityCodec = Fields.object $ do
  condition <- Fields.required "condition" Condition.codec ConditionalException.condition
  exceptions <- Fields.defaulted "exceptions" [] (Common.list (CopyException.codec abilityCodec)) ConditionalException.exceptions
  counters <- Fields.defaulted "counters" Nothing (Common.maybe WithCounters.codec) ConditionalException.counters
  pure ConditionalException.MkConditionalException {ConditionalException.condition = condition, ConditionalException.exceptions = exceptions, ConditionalException.counters = counters}
