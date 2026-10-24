module Parun.Codec.ManaAddedCauseSpec where

import qualified Parun.Codec.ManaAddedCause as ManaAddedCause
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ManaAddedCause as ManaAddedCause

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaAddedCause" $ do
  Spec.it s "ManaAbility" $
    Common.assertCodec
      s
      ManaAddedCause.codec
      ManaAddedCause.ManaAbility
      " {\"type\":\"ManaAbility\"} "
  Spec.it s "Resolution" $
    Common.assertCodec
      s
      ManaAddedCause.codec
      ManaAddedCause.Resolution
      " {\"type\":\"Resolution\"} "
  -- Parun.Codec.RevealCauseSpec's reason: Arm.enum derives the arm list, so this
  -- is what would catch a constructor the derivation missed.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ManaAddedCause.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ManaAddedCause.codec
