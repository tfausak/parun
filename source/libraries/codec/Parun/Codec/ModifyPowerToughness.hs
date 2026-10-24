{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ModifyPowerToughness where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ModifyPowerToughness as ModifyPowerToughness

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec ModifyPowerToughness.ModifyPowerToughness
codec = Fields.object $ do
  power <- Fields.required "power" Quantity.codec ModifyPowerToughness.power
  toughness <- Fields.required "toughness" Quantity.codec ModifyPowerToughness.toughness
  pure
    ModifyPowerToughness.MkModifyPowerToughness
      { ModifyPowerToughness.power = power,
        ModifyPowerToughness.toughness = toughness
      }
