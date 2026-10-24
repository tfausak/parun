module Parun.Codec.PlayPermissionOrigin where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayPermissionOrigin as PlayPermissionOrigin

codec :: Codec.Codec PlayPermissionOrigin.PlayPermissionOrigin
codec = Arm.enum
