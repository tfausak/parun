module Parun.Codec.TurnRoleSpec where

import qualified Parun.Codec.TurnRole as TurnRole
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.TurnRole as TurnRole

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TurnRole" $ do
  Spec.it s "Active" $
    Common.assertCodec
      s
      TurnRole.codec
      TurnRole.Active
      " {\"type\":\"Active\"} "
  Spec.it s "Defending" $
    Common.assertCodec
      s
      TurnRole.codec
      TurnRole.Defending
      " {\"type\":\"Defending\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s TurnRole.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s TurnRole.codec
