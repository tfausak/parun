module Pawl.Codec.ExiledWith where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.ExiledWith as ExiledWith

codec :: Codec.Codec ExiledWith.ExiledWith
codec = Arm.enum
