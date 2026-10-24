{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounterDestination where

import qualified Parun.Codec.CounteredEnd as CounteredEnd
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounterDestination as CounterDestination
import qualified Parun.Types.CounteredEnd as CounteredEndType

-- | The zone is required; the rest are elided at their defaults, so Remand's
-- hand writes only the @zone@ key.
codec :: Codec.Codec CounterDestination.CounterDestination
codec = Fields.object $ do
  zone <- Fields.required "zone" Zone.codec CounterDestination.zone
  position <- Fields.defaulted "position" CounteredEndType.defaultValue CounteredEnd.codec CounterDestination.position
  only <- Fields.defaulted "only" Nothing (Common.maybe (Filter.codec Keyword.codec)) CounterDestination.only
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) CounterDestination.slot
  pure
    CounterDestination.MkCounterDestination
      { CounterDestination.zone = zone,
        CounterDestination.position = position,
        CounterDestination.only = only,
        CounterDestination.slot = slot
      }
