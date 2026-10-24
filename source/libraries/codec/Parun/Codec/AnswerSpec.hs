module Parun.Codec.AnswerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Answer as Answer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Answer as Answer.Type
import qualified Parun.Types.Reply as Reply.Type

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Answer" $ do
  Spec.it s "a prompt and its answer" $
    Common.assertCodec s Answer.codec (Answer.Type.MkAnswer (Text.pack "ChooseDiscard") (Reply.Type.Array [Reply.Type.Text (Text.pack "@card")]) False) " {\"prompt\":\"ChooseDiscard\",\"with\":[\"@card\"]} "
  Spec.it s "an answer of every JSON shape" $
    Common.assertCodec s Answer.codec (Answer.Type.MkAnswer (Text.pack "X") (Reply.Type.Array [Reply.Type.Null, Reply.Type.Boolean True, Reply.Type.Number 3, Reply.Type.Object [(Text.pack "type", Reply.Type.Text (Text.pack "Keep"))]]) False) " {\"prompt\":\"X\",\"with\":[null,true,3,{\"type\":\"Keep\"}]} "
  Spec.it s "an answer the prompt does not offer, on purpose" $
    Common.assertCodec s Answer.codec (Answer.Type.MkAnswer (Text.pack "RollDie") (Reply.Type.Number 7) True) " {\"prompt\":\"RollDie\",\"with\":7,\"unoffered\":true} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Answer.codec
