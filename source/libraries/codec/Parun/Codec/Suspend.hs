{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Suspend where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.SuspendCounters as SuspendCounters
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Suspend as Suspend

-- | A bare object keyed by the record's field names, Parun.Codec.Equip's shape.
-- The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Suspend.Suspend keyword)
codec keywordCodec = Fields.object $ do
  counters <- Fields.required "counters" SuspendCounters.codec Suspend.counters
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Suspend.cost
  pure Suspend.MkSuspend {Suspend.counters = counters, Suspend.cost = cost}
