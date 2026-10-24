module Parun.Codec.PlanarDieFace where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlanarDieFace as PlanarDieFace

codec :: Codec.Codec PlanarDieFace.PlanarDieFace
codec = Arm.enum
