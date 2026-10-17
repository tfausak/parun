module Pawl.Extra.Word64Spec where

import qualified Pawl.Extra.Word64 as Word64
import qualified Pawl.Spec as Spec

spec :: (Applicative m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Extra.Word64" $ do
  Spec.describe s "toNatural" $ do
    Spec.it s "works with zero" $ do
      Spec.assertEq s (Word64.toNatural 0) 0

    Spec.it s "works with the largest Word64" $ do
      Spec.assertEq s (Word64.toNatural 18446744073709551615) 18446744073709551615
