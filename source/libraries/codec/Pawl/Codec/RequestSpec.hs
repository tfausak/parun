module Pawl.Codec.RequestSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.PlayerViewSpec as PlayerViewSpec
import qualified Pawl.Codec.QuestionSpec as QuestionSpec
import qualified Pawl.Codec.Request as Request
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Request as Request

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.Request" $ do
  Spec.it s "every key" $
    Common.assertCodec
      s
      Request.codec
      Request.MkRequest
        { Request.view = PlayerViewSpec.testView,
          Request.question = QuestionSpec.testQuestion,
          Request.problem = Just (Text.pack "expected an array")
        }
      ("{\"view\":" <> PlayerViewSpec.testViewJson <> ",\"question\":" <> QuestionSpec.testQuestionJson <> ",\"problem\":\"expected an array\"}")
  Spec.it s "has a schema" $ Common.assertHasSchema s Request.codec
