module Parun.Extra.EitherSpec where

import qualified Data.Void as Void
import qualified Parun.Extra.Either as Either
import qualified Parun.Spec as Spec

spec :: (Applicative m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Extra.Either" $ do
  Spec.describe s "hush" $ do
    Spec.it s "converts left to nothing" $ do
      Spec.assertEq s (Either.hush (Left 1 :: Either Int Void.Void)) Nothing

    Spec.it s "converts right to just" $ do
      Spec.assertEq s (Either.hush (Right 2 :: Either Void.Void Int)) $ Just 2
