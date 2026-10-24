module Parun.Extra.SemigroupSpec where

import qualified Parun.Extra.Semigroup as Semigroup
import qualified Parun.Spec as Spec

spec :: (Applicative m) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Extra.Semigroup" $ do
  Spec.describe s "around" $ do
    Spec.it s "works" $ do
      Spec.assertEq s (Semigroup.around "<" ">" "x") "<x>"
