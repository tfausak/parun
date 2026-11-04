module Parun.Codec.CardSelection where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CardSelection as CardSelection

codec :: Codec.Codec CardSelection.CardSelection
codec = Arm.enum
