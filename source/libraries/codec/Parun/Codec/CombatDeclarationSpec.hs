module Parun.Codec.CombatDeclarationSpec where

import qualified Parun.Codec.CombatDeclaration as CombatDeclaration
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CombatDeclaration as CombatDeclaration

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CombatDeclaration" $ do
  Spec.it s "Blockers" $
    Common.assertCodec
      s
      CombatDeclaration.codec
      CombatDeclaration.Blockers
      " {\"type\":\"Blockers\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s CombatDeclaration.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s CombatDeclaration.codec
