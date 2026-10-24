{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MonarchWatch where

import qualified Parun.Codec.EventGroup as EventGroup
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MonarchWatch as MonarchWatch

codec :: Codec.Codec MonarchWatch.MonarchWatch
codec = Fields.object $ do
  controller <- Fields.required "controller" PlayerId.codec MonarchWatch.controller
  due <- Fields.defaulted "due" Nothing (Common.maybe EventGroup.codec) MonarchWatch.due
  pure
    MonarchWatch.MkMonarchWatch
      { MonarchWatch.controller = controller,
        MonarchWatch.due = due
      }
