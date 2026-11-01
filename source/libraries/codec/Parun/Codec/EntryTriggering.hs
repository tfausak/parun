module Parun.Codec.EntryTriggering where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.EntryTriggering as EntryTriggering

codec :: Codec.Codec EntryTriggering.EntryTriggering
codec = Arm.enum
