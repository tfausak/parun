module Pawl.Codec.NameChooser where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.NameChooser as NameChooser

codec :: Codec.Codec NameChooser.NameChooser
codec = Arm.enum
