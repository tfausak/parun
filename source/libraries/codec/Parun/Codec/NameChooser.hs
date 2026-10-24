module Parun.Codec.NameChooser where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.NameChooser as NameChooser

codec :: Codec.Codec NameChooser.NameChooser
codec = Arm.enum
