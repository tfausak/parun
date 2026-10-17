{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Request where

import qualified Pawl.Codec.PlayerView as PlayerView
import qualified Pawl.Codec.Question as Question
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Request as Request

codec :: Codec.Codec Request.Request
codec = Fields.object $ do
  view <- Fields.required "view" PlayerView.codec Request.view
  question <- Fields.required "question" Question.codec Request.question
  problem <- Fields.required "problem" (Common.maybe Common.text) Request.problem
  pure Request.MkRequest {Request.view = view, Request.question = question, Request.problem = problem}
