module Parun.Codec.Holder where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Holder as Holder

codec :: Codec.Codec Holder.Holder
codec = Arm.enum
