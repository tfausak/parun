module Parun.Extra.ParsecSpec where

import qualified Data.Char as Char
import qualified Data.Text as Text
import qualified Parun.Extra.Parsec as Parsec
import qualified Parun.Spec as Spec
import qualified Text.Parsec as Parsec

spec :: (Applicative m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Extra.Parsec" $ do
  Spec.describe s "parseString" $ do
    Spec.it s "fails with no match" $ do
      Spec.assertEq s (Parsec.parseString Parsec.digit "x") Nothing

    Spec.it s "succeeds with a match" $ do
      Spec.assertEq s (Parsec.parseString Parsec.digit "1") $ Just '1'

    Spec.it s "allows unconsumed input" $ do
      Spec.assertEq s (Parsec.parseString Parsec.digit "2x") $ Just '2'

  Spec.describe s "parseText" $ do
    Spec.it s "fails with no match" $ do
      Spec.assertEq s (Parsec.parseText Parsec.digit "x") Nothing

    Spec.it s "succeeds with a match" $ do
      Spec.assertEq s (Parsec.parseText Parsec.digit "1") $ Just '1'

  Spec.describe s "takeWhile" $ do
    Spec.it s "takes the matching prefix" $ do
      Spec.assertEq s (Parsec.parseText ((,) <$> Parsec.takeWhile Char.isDigit <*> Parsec.getInput) "12x") $ Just (Text.pack "12", Text.pack "x")

    Spec.it s "succeeds with no match" $ do
      Spec.assertEq s (Parsec.parseText (Parsec.takeWhile Char.isDigit) "x") . Just $ Text.pack ""

    Spec.it s "consumes nothing with no match" $ do
      Spec.assertEq s (Parsec.parseText (Parsec.choice [Parsec.takeWhile Char.isDigit *> Parsec.char 'x', Parsec.char 'y']) "y") $ Just 'y'

    Spec.it s "reports a consumed match" $ do
      Spec.assertEq s (Parsec.parseText (Parsec.choice [Parsec.takeWhile Char.isDigit *> Parsec.char 'x', Parsec.char '1']) "1") Nothing

    Spec.it s "tracks the source position" $ do
      Spec.assertEq s (fmap (\p -> (Parsec.sourceLine p, Parsec.sourceColumn p)) $ Parsec.parseText (Parsec.takeWhile (/= 'x') *> Parsec.getPosition) "a\nbc x") $ Just (2, 4)
