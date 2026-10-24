module Parun.Codec.AbilityNameSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AbilityName" $ do
  Spec.it s "MkAbilityName" $
    Common.assertCodec
      s
      AbilityName.codec
      (AbilityName.MkAbilityName (Text.pack "a"))
      " \"a\" "

  Spec.it s "MkAbilityName, a second name" $
    Common.assertCodec
      s
      AbilityName.codec
      (AbilityName.MkAbilityName (Text.pack "b"))
      " \"b\" "

  Spec.it s "has a schema" $
    Common.assertHasSchema s AbilityName.codec

  Spec.it s "rejects a non-string" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " 1 ") >>= Codec.decode AbilityName.codec))
      "expected a decode failure"
