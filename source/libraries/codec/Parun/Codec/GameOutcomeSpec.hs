module Parun.Codec.GameOutcomeSpec where

import qualified Parun.Codec.GameOutcome as GameOutcome
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.GameOutcome as GameOutcome

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.GameOutcome" $ do
  Spec.it s "Win" $
    Common.assertCodec
      s
      GameOutcome.codec
      GameOutcome.Win
      " {\"type\":\"Win\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s GameOutcome.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s GameOutcome.codec
