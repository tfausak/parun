{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Activation where

import qualified Parun.Codec.Choices as Choices
import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Activation as Activation

codec :: Codec.Codec Activation.Activation
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec Activation.object
  ability <- Fields.defaulted "ability" Nothing (Common.maybe Common.natural) Activation.ability
  choices <- Fields.contramap Activation.choices Choices.fields
  pure
    Activation.MkActivation
      { Activation.object = object,
        Activation.ability = ability,
        Activation.choices = choices
      }
