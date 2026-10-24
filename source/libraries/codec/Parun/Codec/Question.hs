{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Question where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Reply as Reply
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Question as Question

codec :: Codec.Codec Question.Question
codec = Fields.object $ do
  seat <- Fields.required "seat" PlayerId.codec Question.seat
  kind <- Fields.required "kind" Common.text Question.kind
  offer <- Fields.required "offer" Reply.codec Question.offer
  pure Question.MkQuestion {Question.seat = seat, Question.kind = kind, Question.offer = offer}
