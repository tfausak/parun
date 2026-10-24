module Parun.Codec.PlayerIdSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerId" $ do
  Spec.it s "MkPlayerId" $
    Common.assertCodec
      s
      PlayerId.codec
      (PlayerId.MkPlayerId 1)
      " 1 "

  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerId.codec

  Spec.it s "rejects a negative id" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " -1 ") >>= Codec.decode PlayerId.codec))
      "expected a decode failure"
