module Parun.Codec.DesignationSpec where

import qualified Parun.Codec.Designation as Designation
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Designation as Designation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Designation" $ do
  Spec.it s "Renowned" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Renowned
      " {\"type\":\"Renowned\"} "
  Spec.it s "Monstrous" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Monstrous
      " {\"type\":\"Monstrous\"} "
  Spec.it s "Suspected" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Suspected
      " {\"type\":\"Suspected\"} "
  Spec.it s "Solved" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Solved
      " {\"type\":\"Solved\"} "
  Spec.it s "Saddled" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Saddled
      " {\"type\":\"Saddled\"} "
  Spec.it s "Prepared" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Prepared
      " {\"type\":\"Prepared\"} "
  Spec.it s "Harnessed" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Harnessed
      " {\"type\":\"Harnessed\"} "
  Spec.it s "Embalmed" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Embalmed
      " {\"type\":\"Embalmed\"} "
  Spec.it s "Sprocket1" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Sprocket1
      " {\"type\":\"Sprocket1\"} "
  Spec.it s "AlphaSector" $
    Common.assertCodec
      s
      Designation.codec
      Designation.AlphaSector
      " {\"type\":\"AlphaSector\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Designation.codec
