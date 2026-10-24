module Parun.Codec.AttackOptionSpec where

import qualified Parun.Codec.AttackOption as AttackOption
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackOption as AttackOption

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackOption" $ do
  Spec.it s "MultiplePlayers" $
    Common.assertCodec
      s
      AttackOption.codec
      AttackOption.MultiplePlayers
      " {\"type\":\"MultiplePlayers\"} "
  Spec.it s "Leftward" $
    Common.assertCodec
      s
      AttackOption.codec
      AttackOption.Leftward
      " {\"type\":\"Leftward\"} "
  Spec.it s "Rightward" $
    Common.assertCodec
      s
      AttackOption.codec
      AttackOption.Rightward
      " {\"type\":\"Rightward\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s AttackOption.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s AttackOption.codec
