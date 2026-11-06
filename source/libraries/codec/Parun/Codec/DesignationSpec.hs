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
      " \"Renowned\" "
  Spec.it s "Monstrous" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Monstrous
      " \"Monstrous\" "
  Spec.it s "Suspected" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Suspected
      " \"Suspected\" "
  Spec.it s "Solved" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Solved
      " \"Solved\" "
  Spec.it s "Saddled" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Saddled
      " \"Saddled\" "
  Spec.it s "Prepared" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Prepared
      " \"Prepared\" "
  Spec.it s "Harnessed" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Harnessed
      " \"Harnessed\" "
  Spec.it s "Embalmed" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Embalmed
      " \"Embalmed\" "
  Spec.it s "Sprocket1" $
    Common.assertCodec
      s
      Designation.codec
      Designation.Sprocket1
      " \"Sprocket1\" "
  Spec.it s "AlphaSector" $
    Common.assertCodec
      s
      Designation.codec
      Designation.AlphaSector
      " \"AlphaSector\" "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Designation.codec
