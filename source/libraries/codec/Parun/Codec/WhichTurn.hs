module Parun.Codec.WhichTurn where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.WhichTurn as WhichTurn

codec :: Codec.Codec WhichTurn.WhichTurn
codec = Arm.enum
