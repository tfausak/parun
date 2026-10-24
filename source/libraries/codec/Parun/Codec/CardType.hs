module Parun.Codec.CardType where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CardType as CardType

codec :: Codec.Codec CardType.CardType
codec = Arm.enum
