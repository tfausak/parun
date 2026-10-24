module Parun.Codec.ProductionTag where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ProductionTag as ProductionTag

codec :: Codec.Codec ProductionTag.ProductionTag
codec = Arm.enum
