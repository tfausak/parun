{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SetPowerToughness where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SetPowerToughness as SetPowerToughness

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464). This is the one place the order of the
-- two boxes is stated, and it is now stated as key names.
codec :: Codec.Codec SetPowerToughness.SetPowerToughness
codec = Fields.object $ do
  power <- Fields.required "power" Common.integer SetPowerToughness.power
  toughness <- Fields.required "toughness" Common.integer SetPowerToughness.toughness
  pure
    SetPowerToughness.MkSetPowerToughness
      { SetPowerToughness.power = power,
        SetPowerToughness.toughness = toughness
      }
