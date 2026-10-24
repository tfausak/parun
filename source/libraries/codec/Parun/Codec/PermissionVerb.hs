module Parun.Codec.PermissionVerb where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PermissionVerb as PermissionVerb

codec :: Codec.Codec PermissionVerb.PermissionVerb
codec = Arm.enum
