module Parun.Codec.ReplacementProvenance where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ReplacementProvenance as ReplacementProvenance

codec :: Codec.Codec ReplacementProvenance.ReplacementProvenance
codec = Arm.enum
