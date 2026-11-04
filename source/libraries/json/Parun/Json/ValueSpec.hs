module Parun.Json.ValueSpec where

import qualified Parun.Extra.Builder as Builder
import qualified Parun.Extra.Parsec as Parsec
import qualified Parun.Json.Value as Value
import qualified Parun.Spec as Spec

spec :: (Applicative m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Json.Value" $ do
  Spec.describe s "decode" $ do
    Spec.it s "parses null" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "null") $ Just Value.null

    Spec.it s "parses a boolean" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "false") . Just $ Value.boolean False

    Spec.it s "parses a number" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "0") . Just $ Value.integer 0

    Spec.it s "parses a string" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "\"\"") . Just $ Value.string ""

    Spec.it s "parses an array" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "[]") . Just $ Value.array []

    Spec.it s "parses an object" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "{}") . Just $ Value.object []

    Spec.it s "accepts leading blanks" $ do
      Spec.assertEq s (Parsec.parseText Value.decode " null") $ Just Value.null

    Spec.it s "accepts trailing blanks" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "null ") $ Just Value.null

    Spec.it s "accepts each kind of blank" $ do
      Spec.assertEq s (Parsec.parseText Value.decode " \t\n\rnull \t\n\r") $ Just Value.null

    Spec.it s "fails with another blank" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "\fnull") Nothing

    Spec.it s "fails with no input" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "") Nothing

    Spec.it s "fails with an unknown token" $ do
      Spec.assertEq s (Parsec.parseText Value.decode "x") Nothing

  Spec.describe s "encode" $ do
    Spec.it s "encodes null" $ do
      Spec.assertEq s (Builder.toString $ Value.encode Value.null) "null"

    Spec.it s "encodes a boolean" $ do
      Spec.assertEq s (Builder.toString . Value.encode $ Value.boolean False) "false"

    Spec.it s "encodes a number" $ do
      Spec.assertEq s (Builder.toString . Value.encode $ Value.integer 0) "0"

    Spec.it s "encodes a string" $ do
      Spec.assertEq s (Builder.toString . Value.encode $ Value.string "") "\"\""

    Spec.it s "encodes an array" $ do
      Spec.assertEq s (Builder.toString . Value.encode $ Value.array []) "[]"

    Spec.it s "encodes an object" $ do
      Spec.assertEq s (Builder.toString . Value.encode $ Value.object []) "{}"
