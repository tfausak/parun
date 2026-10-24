{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Casting where

import qualified Parun.Codec.Choices as Choices
import qualified Parun.Codec.Reference as Reference
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Casting as Casting

codec :: Codec.Codec Casting.Casting
codec = Fields.object $ do
  object <- Fields.required "object" Reference.codec Casting.object
  choices <- Fields.contramap Casting.choices Choices.fields
  faceDown <- Fields.defaulted "faceDown" Nothing (Common.maybe Common.boolean) Casting.faceDown
  pure
    Casting.MkCasting
      { Casting.object = object,
        Casting.choices = choices,
        Casting.faceDown = faceDown
      }
