{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Answer where

import qualified Parun.Codec.Reply as Reply
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Answer as Answer

codec :: Codec.Codec Answer.Answer
codec = Fields.object $ do
  prompt <- Fields.required "prompt" Common.text Answer.prompt
  with <- Fields.required "with" Reply.codec Answer.with
  unoffered <- Fields.defaulted "unoffered" False Common.boolean Answer.unoffered
  pure Answer.MkAnswer {Answer.prompt = prompt, Answer.with = with, Answer.unoffered = unoffered}
