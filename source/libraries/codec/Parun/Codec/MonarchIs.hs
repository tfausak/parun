{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.MonarchIs where

import qualified Parun.Codec.Label as Label
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.MonarchIs as MonarchIs

-- | @"player": null@ when nobody is the monarch.
codec :: Codec.Codec MonarchIs.MonarchIs
codec = Fields.object $ do
  player <- Fields.required "player" (Common.maybe Label.codec) MonarchIs.player
  pure MonarchIs.MkMonarchIs {MonarchIs.player = player}
