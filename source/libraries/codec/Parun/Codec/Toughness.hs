module Parun.Codec.Toughness where

import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Toughness as Toughness

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- a @$defs@ entry under this newtype's own name.
codec :: Codec.Codec Toughness.Toughness
codec = Common.wrapper Quantity.codec Toughness.MkToughness Toughness.unwrap
