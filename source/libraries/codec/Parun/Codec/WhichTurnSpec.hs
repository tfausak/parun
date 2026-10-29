module Parun.Codec.WhichTurnSpec where

import qualified Parun.Codec.WhichTurn as WhichTurn
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.WhichTurn as WhichTurn

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.WhichTurn" $ do
  Spec.it s "ThisTurn" $
    Common.assertCodec
      s
      WhichTurn.codec
      WhichTurn.ThisTurn
      " {\"type\":\"ThisTurn\"} "
  Spec.it s "LastTurn" $
    Common.assertCodec
      s
      WhichTurn.codec
      WhichTurn.LastTurn
      " {\"type\":\"LastTurn\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s WhichTurn.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s WhichTurn.codec
