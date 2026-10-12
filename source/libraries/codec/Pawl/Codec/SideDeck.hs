module Pawl.Codec.SideDeck where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.SideDeck as SideDeck

codec :: Codec.Codec SideDeck.SideDeck
codec = Arm.enum
