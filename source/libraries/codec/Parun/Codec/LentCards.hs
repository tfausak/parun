module Parun.Codec.LentCards where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LentCards as LentCards

codec :: Codec.Codec LentCards.LentCards
codec = Arm.enum
