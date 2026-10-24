module Parun.Codec.SearchDestination where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.SearchDestination as SearchDestination

codec :: Codec.Codec SearchDestination.SearchDestination
codec = Arm.enum
