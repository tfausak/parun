{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ReturnWatch where

import qualified Parun.Codec.ReturnEnding as ReturnEnding
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ReturnWatch as ReturnWatch

codec :: Codec.Codec ReturnWatch.ReturnWatch
codec = Fields.object $ do
  ending <- Fields.required "ending" ReturnEnding.codec ReturnWatch.ending
  zone <- Fields.required "zone" Zone.codec ReturnWatch.zone
  pure
    ReturnWatch.MkReturnWatch
      { ReturnWatch.ending = ending,
        ReturnWatch.zone = zone
      }
