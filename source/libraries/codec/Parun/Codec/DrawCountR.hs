{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DrawCountR where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.DrawCountRewrite as DrawCountRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DrawCountR as DrawCountR

codec :: Codec.Codec DrawCountR.DrawCountR
codec = Fields.object $ do
  whose <- Fields.required "whose" ControllerRelation.codec DrawCountR.whose
  atLeast <- Fields.required "atLeast" Common.natural DrawCountR.atLeast
  rewrite <- Fields.required "rewrite" DrawCountRewrite.codec DrawCountR.rewrite
  pure
    DrawCountR.MkDrawCountR
      { DrawCountR.whose = whose,
        DrawCountR.atLeast = atLeast,
        DrawCountR.rewrite = rewrite
      }
