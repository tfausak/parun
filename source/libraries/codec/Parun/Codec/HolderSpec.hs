module Parun.Codec.HolderSpec where

import qualified Parun.Codec.Holder as Holder
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Holder as Holder

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Holder" $ do
  Spec.it s "Owner" $
    Common.assertCodec
      s
      Holder.codec
      Holder.Owner
      " {\"type\":\"Owner\"} "
  -- Parun.Codec.DamageKindSpec's reason: Arm.enum derives the arm list from the
  -- type, so this is what would catch a constructor the derivation missed or two
  -- that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s Holder.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s Holder.codec
