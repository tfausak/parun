module Parun.Codec.TeamIdSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.TeamId as TeamId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.TeamId as TeamId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TeamId" $ do
  Spec.it s "MkTeamId" $
    Common.assertCodec
      s
      TeamId.codec
      (TeamId.MkTeamId 1)
      " 1 "

  Spec.it s "has a schema" $
    Common.assertHasSchema s TeamId.codec

  Spec.it s "rejects a negative id" $
    Spec.assertBool
      s
      (Either.isLeft (Common.parse (Text.pack " -1 ") >>= Codec.decode TeamId.codec))
      "expected a decode failure"
