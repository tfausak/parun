module Parun.Codec.ModeIndexSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.ModeIndex as ModeIndex
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ModeIndex as ModeIndex

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ModeIndex" $ do
  Spec.it s "MkModeIndex" $
    Common.assertCodec
      s
      ModeIndex.codec
      (ModeIndex.MkModeIndex 2)
      " 2 "

  Spec.it s "has a schema" $
    Common.assertHasSchema s ModeIndex.codec

  -- The wrapped type is Natural, so a negative number is a decode failure
  -- rather than a wrapped negative going through a partial fromInteger.
  Spec.it s "rejects a negative number" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " -1 ") >>= Codec.decode ModeIndex.codec))
      "expected a decode failure"
