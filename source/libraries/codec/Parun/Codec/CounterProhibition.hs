{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterProhibition where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterProhibition as CounterProhibition
import qualified Parun.Types.Filter as Filter

-- | An object with named keys, Parun.Codec.TargetRestriction's shape: the
-- counterers default to every spell and ability, which is what every card but
-- Autumn's Veil says.
codec :: Codec.Codec CounterProhibition.CounterProhibition
codec = Fields.object $ do
  countered <- Fields.required "countered" (Filter.codec Keyword.codec) CounterProhibition.countered
  counterers <- Fields.defaulted "counterers" (Filter.And []) (Filter.codec Keyword.codec) CounterProhibition.counterers
  pure CounterProhibition.MkCounterProhibition {CounterProhibition.countered = countered, CounterProhibition.counterers = counterers}
