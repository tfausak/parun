module Parun.Codec.Power where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Power as Power

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- a @$defs@ entry under this newtype's own name.
codec :: Codec.Codec Power.Power
codec = Common.wrapper Quantity.codec Power.MkPower Power.unwrap
