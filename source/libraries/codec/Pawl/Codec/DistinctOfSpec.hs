module Pawl.Codec.DistinctOfSpec where

import qualified Pawl.Codec.DistinctOf as DistinctOf
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.DistinctOf as DistinctOf

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.DistinctOf" $ do
  Spec.it s "BasicLandTypes" $
    Common.assertCodec
      s
      DistinctOf.codec
      DistinctOf.BasicLandTypes
      " {\"type\":\"BasicLandTypes\"} "
  -- Pawl.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s DistinctOf.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s DistinctOf.codec
