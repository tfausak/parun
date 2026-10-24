{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Paying where

import qualified Parun.Codec.Choices as Choices
import qualified Parun.Codec.PaymentDecision as PaymentDecision
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Paying as Paying

codec :: Codec.Codec Paying.Paying
codec = Fields.object $ do
  decision <- Fields.required "decision" PaymentDecision.codec Paying.decision
  choices <- Fields.contramap Paying.choices Choices.fields
  pure Paying.MkPaying {Paying.decision = decision, Paying.choices = choices}
