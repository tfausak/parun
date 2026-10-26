module Parun.Codec.ChangeModeSpec where

import qualified Parun.Codec.ChangeMode as ChangeMode
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChangeMode as ChangeMode

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChangeMode" $ do
  Spec.it s "Replace" $
    Common.assertCodec
      s
      ChangeMode.codec
      ChangeMode.Replace
      " {\"type\":\"Replace\"} "
  Spec.it s "InAddition" $
    Common.assertCodec
      s
      ChangeMode.codec
      ChangeMode.InAddition
      " {\"type\":\"InAddition\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s ChangeMode.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s ChangeMode.codec
