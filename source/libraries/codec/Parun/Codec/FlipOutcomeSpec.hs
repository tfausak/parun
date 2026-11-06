module Parun.Codec.FlipOutcomeSpec where

import qualified Parun.Codec.FlipOutcome as FlipOutcome
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.FlipOutcome as FlipOutcome

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.FlipOutcome" $ do
  Spec.it s "Lost" $
    Common.assertCodec
      s
      FlipOutcome.codec
      FlipOutcome.Lost
      " \"Lost\" "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s FlipOutcome.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s FlipOutcome.codec
