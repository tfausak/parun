module Parun.Codec.LibraryDeparture where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LibraryDeparture as LibraryDeparture

codec :: Codec.Codec LibraryDeparture.LibraryDeparture
codec = Arm.enum
