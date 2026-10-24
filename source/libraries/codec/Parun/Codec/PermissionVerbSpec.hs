module Parun.Codec.PermissionVerbSpec where

import qualified Parun.Codec.PermissionVerb as PermissionVerb
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PermissionVerb as PermissionVerb

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PermissionVerb" $ do
  Spec.it s "Cast" $
    Common.assertCodec
      s
      PermissionVerb.codec
      PermissionVerb.Cast
      " {\"type\":\"Cast\"} "
  Spec.it s "Play" $
    Common.assertCodec
      s
      PermissionVerb.codec
      PermissionVerb.Play
      " {\"type\":\"Play\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s PermissionVerb.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s PermissionVerb.codec
