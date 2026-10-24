module Parun.Codec.PaymentDecision where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PaymentDecision as PaymentDecision

-- | Nullary tags, derived from the type by Arm.enum.
codec :: Codec.Codec PaymentDecision.PaymentDecision
codec = Arm.enum
