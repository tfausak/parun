module Parun.Codec.LibraryPosition where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LibraryPosition as LibraryPosition

codec :: Codec.Codec LibraryPosition.LibraryPosition
codec = Arm.enum
