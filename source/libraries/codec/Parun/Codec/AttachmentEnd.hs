module Parun.Codec.AttachmentEnd where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AttachmentEnd as AttachmentEnd

codec :: Codec.Codec AttachmentEnd.AttachmentEnd
codec = Arm.enum
