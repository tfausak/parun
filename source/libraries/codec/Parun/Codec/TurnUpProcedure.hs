module Parun.Codec.TurnUpProcedure where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnUpProcedure as TurnUpProcedure

codec :: Codec.Codec TurnUpProcedure.TurnUpProcedure
codec = Arm.enum
