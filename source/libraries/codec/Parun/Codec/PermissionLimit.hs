module Parun.Codec.PermissionLimit where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PermissionLimit as PermissionLimit

codec :: Codec.Codec PermissionLimit.PermissionLimit
codec = Arm.enum
