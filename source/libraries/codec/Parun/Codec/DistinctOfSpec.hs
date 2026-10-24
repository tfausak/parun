module Parun.Codec.DistinctOfSpec where

import qualified Parun.Codec.DistinctOf as DistinctOf
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DistinctOf as DistinctOf

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DistinctOf" $ do
  Spec.it s "BasicLandTypes" $
    Common.assertCodec
      s
      DistinctOf.codec
      DistinctOf.BasicLandTypes
      " {\"type\":\"BasicLandTypes\"} "
  -- Parun.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s DistinctOf.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s DistinctOf.codec
