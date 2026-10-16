module Pawl.Codec.ExiledPile where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.ExiledPile as ExiledPile

codec :: Codec.Codec ExiledPile.ExiledPile
codec = Arm.enum
