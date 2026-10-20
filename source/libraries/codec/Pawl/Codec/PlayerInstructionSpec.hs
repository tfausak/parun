module Pawl.Codec.PlayerInstructionSpec where

import qualified Pawl.Codec.PlayerInstruction as PlayerInstruction
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.PlayerInstruction as PlayerInstruction

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.PlayerInstruction" $ do
  Spec.it s "FlipCoin" $
    Common.assertCodec
      s
      PlayerInstruction.codec
      PlayerInstruction.FlipCoin
      " {\"type\":\"FlipCoin\"} "
  -- Pawl.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s PlayerInstruction.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerInstruction.codec
