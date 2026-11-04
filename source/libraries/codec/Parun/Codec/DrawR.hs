{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DrawR where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.DrawRewrite as DrawRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DrawR as DrawR

codec :: (Eq effect, Typeable.Typeable effect) => Codec.Codec effect -> Codec.Codec (DrawR.DrawR effect)
codec effectCodec = Fields.object $ do
  whose <- Fields.required "whose" ControllerRelation.codec DrawR.whose
  exceptFirstInDrawStep <- Fields.defaulted "exceptFirstInDrawStep" False Common.boolean DrawR.exceptFirstInDrawStep
  rewrite <- Fields.required "rewrite" (DrawRewrite.codec effectCodec) DrawR.rewrite
  pure
    DrawR.MkDrawR
      { DrawR.whose = whose,
        DrawR.exceptFirstInDrawStep = exceptFirstInDrawStep,
        DrawR.rewrite = rewrite
      }
