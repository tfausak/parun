{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ViewIs where

import qualified Parun.Codec.Label as Label
import qualified Parun.Codec.Reference as Reference
import qualified Parun.Codec.Reply as Reply
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ViewIs as ViewIs

codec :: Codec.Codec ViewIs.ViewIs
codec = Fields.object $ do
  view <- Fields.required "of" Arm.keyedEnum ViewIs.view
  player <- Fields.defaulted "player" Nothing (Common.maybe Label.codec) ViewIs.player
  object <- Fields.defaulted "object" Nothing (Common.maybe Reference.codec) ViewIs.object
  zone <- Fields.defaulted "zone" Nothing (Common.maybe Arm.keyedEnum) ViewIs.zone
  is <- Fields.required "is" Reply.codec ViewIs.is
  pure ViewIs.MkViewIs {ViewIs.view = view, ViewIs.player = player, ViewIs.object = object, ViewIs.zone = zone, ViewIs.is = is}
