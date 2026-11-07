module Parun.Codec.AttackCompanySpec where

import qualified Parun.Codec.AttackCompany as AttackCompany
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AloneAmong as AloneAmong
import qualified Parun.Types.AttackCompany as AttackCompany
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackCompany" $ do
  Spec.it s "AnyCompany" $
    Common.assertCodec s AttackCompany.codec AttackCompany.AnyCompany " {\"type\":\"AnyCompany\"} "
  Spec.it s "Alone" $
    Common.assertCodec s AttackCompany.codec (AttackCompany.Alone AloneAmong.EveryAttacker) " {\"type\":\"Alone\"} "
  Spec.it s "Alone, attacking a player" $
    Common.assertCodec s AttackCompany.codec (AttackCompany.Alone AloneAmong.AttackersOfItsPlayer) " {\"type\":\"Alone\",\"value\":\"AttackersOfItsPlayer\"} "
  Spec.it s "WithAnother" $
    Common.assertCodec s AttackCompany.codec (AttackCompany.WithAnother Filter.IsToken) " {\"type\":\"WithAnother\",\"value\":{\"type\":\"IsToken\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackCompany.codec
