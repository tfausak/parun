{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Taking where

import qualified Parun.Codec.Choices as Choices
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Taking as Taking

codec :: Codec.Codec Taking.Taking
codec = Fields.object $ do
  action <- Fields.required "action" Common.text Taking.action
  choices <- Fields.contramap Taking.choices Choices.fields
  pure
    Taking.MkTaking
      { Taking.action = action,
        Taking.choices = choices
      }
