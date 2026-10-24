{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Request where

import qualified Parun.Codec.PlayerView as PlayerView
import qualified Parun.Codec.Question as Question
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Request as Request

codec :: Codec.Codec Request.Request
codec = Fields.object $ do
  view <- Fields.required "view" (Common.maybe PlayerView.codec) Request.view
  question <- Fields.required "question" Question.codec Request.question
  problem <- Fields.required "problem" (Common.maybe Common.text) Request.problem
  pure Request.MkRequest {Request.view = view, Request.question = question, Request.problem = problem}
