{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PowerToughnessIs where

import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PowerToughnessIs as PowerToughnessIs

codec :: Codec.Codec PowerToughnessIs.PowerToughnessIs
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec PowerToughnessIs.object
  power <- Fields.required "power" Common.integer PowerToughnessIs.power
  toughness <- Fields.required "toughness" Common.integer PowerToughnessIs.toughness
  pure PowerToughnessIs.MkPowerToughnessIs {PowerToughnessIs.object = object, PowerToughnessIs.power = power, PowerToughnessIs.toughness = toughness}
