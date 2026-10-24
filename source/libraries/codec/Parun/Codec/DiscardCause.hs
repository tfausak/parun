module Parun.Codec.DiscardCause where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.DiscardCause as DiscardCause

codec :: Codec.Codec DiscardCause.DiscardCause
codec = Arm.enum
