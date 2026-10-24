module Parun.Codec.OptionalDecision where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.OptionalDecision as OptionalDecision

-- | Nullary tags, derived from the type by Arm.enum.
codec :: Codec.Codec OptionalDecision.OptionalDecision
codec = Arm.enum
