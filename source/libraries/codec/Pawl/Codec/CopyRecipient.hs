module Pawl.Codec.CopyRecipient where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.CopyRecipient as CopyRecipient

codec :: Codec.Codec CopyRecipient.CopyRecipient
codec = Arm.enum
