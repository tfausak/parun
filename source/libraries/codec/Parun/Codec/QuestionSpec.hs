module Parun.Codec.QuestionSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Question as Question
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Question as Question
import qualified Parun.Types.Reply as Reply

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Question" $ do
  Spec.it s "every key" $ Common.assertCodec s Question.codec testQuestion testQuestionJson
  Spec.it s "has a schema" $ Common.assertHasSchema s Question.codec

testQuestion :: Question.Question
testQuestion =
  Question.MkQuestion
    { Question.seat = PlayerId.MkPlayerId 1,
      Question.kind = Text.pack "DeclareAttackers",
      Question.offer = Reply.Array [Reply.Text (Text.pack "$7")]
    }

testQuestionJson :: String
testQuestionJson = "{\"seat\":1,\"kind\":\"DeclareAttackers\",\"offer\":[\"$7\"]}"
