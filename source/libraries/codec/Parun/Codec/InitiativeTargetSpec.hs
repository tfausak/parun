module Parun.Codec.InitiativeTargetSpec where

import qualified Parun.Codec.InitiativeTarget as InitiativeTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.InitiativeTarget as InitiativeTarget

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.InitiativeTarget" $ do
  Spec.it s "TheController" $
    Common.assertCodec
      s
      InitiativeTarget.codec
      InitiativeTarget.TheController
      " {\"type\":\"TheController\"} "
  Spec.it s "ControllerOfSource" $
    Common.assertCodec
      s
      InitiativeTarget.codec
      InitiativeTarget.ControllerOfSource
      " {\"type\":\"ControllerOfSource\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s InitiativeTarget.codec
