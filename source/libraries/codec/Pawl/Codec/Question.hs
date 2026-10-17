{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Question where

import qualified Pawl.Codec.PlayerId as PlayerId
import qualified Pawl.Codec.Reply as Reply
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Question as Question

codec :: Codec.Codec Question.Question
codec = Fields.object $ do
  seat <- Fields.required "seat" PlayerId.codec Question.seat
  kind <- Fields.required "kind" Common.text Question.kind
  offer <- Fields.required "offer" Reply.codec Question.offer
  pure Question.MkQuestion {Question.seat = seat, Question.kind = kind, Question.offer = offer}
