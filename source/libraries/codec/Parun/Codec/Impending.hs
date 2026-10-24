{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Impending where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Cost as Cost
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Impending as Impending

-- | A bare object keyed by the record's field names, Parun.Codec.Reinforce's
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (Impending.Impending keyword)
codec keywordCodec = Fields.object $ do
  counters <- Fields.required "counters" Common.natural Impending.counters
  cost <- Fields.required "cost" (Cost.codec keywordCodec) Impending.cost
  pure Impending.MkImpending {Impending.counters = counters, Impending.cost = cost}
