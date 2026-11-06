module Parun.Codec.FaceDownReasonSpec where

import qualified Parun.Codec.FaceDownReason as FaceDownReason
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.FaceDownReason as FaceDownReason

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FaceDownReason" $ do
  Spec.it s "Morphed" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.Morphed
      " \"Morphed\" "
  Spec.it s "Disguised" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.Disguised
      " \"Disguised\" "
  Spec.it s "Manifested" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.Manifested
      " \"Manifested\" "
  Spec.it s "Cloaked" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.Cloaked
      " \"Cloaked\" "
  Spec.it s "TurnedFaceDown" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.TurnedFaceDown
      " \"TurnedFaceDown\" "
  Spec.it s "EnteredFaceDown" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.EnteredFaceDown
      " \"EnteredFaceDown\" "
  Spec.it s "CastFaceDown" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.CastFaceDown
      " \"CastFaceDown\" "
  Spec.it s "HiddenAgenda" $
    Common.assertCodec
      s
      FaceDownReason.codec
      FaceDownReason.HiddenAgenda
      " \"HiddenAgenda\" "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s FaceDownReason.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s FaceDownReason.codec
