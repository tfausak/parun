{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CopyClause where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.CopyException as CopyException
import qualified Parun.Codec.WithCounters as WithCounters
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CopyClause as CopyClause

-- | A bare object keyed by the record's field names, every key defaulted: most
-- parts state no condition (Quicksilver Gargantuan), Altered Ego's states
-- counters alone and Vizier of Many Faces' exceptions alone.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (CopyClause.CopyClause ability)
codec abilityCodec = Fields.object $ do
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) CopyClause.condition
  exceptions <- Fields.defaulted "exceptions" [] (Common.list (CopyException.codec abilityCodec)) CopyClause.exceptions
  counters <- Fields.defaulted "counters" Nothing (Common.maybe WithCounters.codec) CopyClause.counters
  pure CopyClause.MkCopyClause {CopyClause.condition = condition, CopyClause.exceptions = exceptions, CopyClause.counters = counters}
