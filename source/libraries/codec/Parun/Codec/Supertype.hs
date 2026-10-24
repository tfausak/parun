module Parun.Codec.Supertype where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Supertype as Supertype

codec :: Codec.Codec Supertype.Supertype
codec = Arm.enum
