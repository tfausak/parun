module Parun.Codec.PlayerDesignation where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerDesignation as PlayerDesignation

codec :: Codec.Codec PlayerDesignation.PlayerDesignation
codec = Arm.enum
