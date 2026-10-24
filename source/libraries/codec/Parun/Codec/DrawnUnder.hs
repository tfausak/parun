{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DrawnUnder where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.RevealTiming as RevealTiming
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DrawnUnder as DrawnUnder

codec :: Codec.Codec DrawnUnder.DrawnUnder
codec = Fields.object $ do
  under <- Fields.required "under" ObjectId.codec DrawnUnder.under
  timing <- Fields.required "timing" RevealTiming.codec DrawnUnder.timing
  pure
    DrawnUnder.MkDrawnUnder
      { DrawnUnder.under = under,
        DrawnUnder.timing = timing
      }
