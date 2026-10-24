module Parun.Codec.CopyRecipient where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CopyRecipient as CopyRecipient

codec :: Codec.Codec CopyRecipient.CopyRecipient
codec = Arm.enum
