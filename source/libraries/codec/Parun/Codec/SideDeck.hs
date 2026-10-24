module Parun.Codec.SideDeck where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.SideDeck as SideDeck

codec :: Codec.Codec SideDeck.SideDeck
codec = Arm.enum
