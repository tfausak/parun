{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.SetBasePowerToughness where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.SetBasePowerToughness as SetBasePowerToughness

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec SetBasePowerToughness.SetBasePowerToughness
codec = Fields.object $ do
  power <- Fields.defaulted "power" Nothing (Common.maybe Quantity.codec) SetBasePowerToughness.power
  toughness <- Fields.defaulted "toughness" Nothing (Common.maybe Quantity.codec) SetBasePowerToughness.toughness
  pure
    SetBasePowerToughness.MkSetBasePowerToughness
      { SetBasePowerToughness.power = power,
        SetBasePowerToughness.toughness = toughness
      }
