{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeLossR where

import qualified Parun.Codec.LifeLossPattern as LifeLossPattern
import qualified Parun.Codec.LifeLossRewrite as LifeLossRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.LifeLossR as LifeLossR

codec :: Codec.Codec LifeLossR.LifeLossR
codec = Fields.object $ do
  matching <- Fields.required "matching" LifeLossPattern.codec LifeLossR.matching
  rewrite <- Fields.required "rewrite" LifeLossRewrite.codec LifeLossR.rewrite
  pure
    LifeLossR.MkLifeLossR
      { LifeLossR.matching = matching,
        LifeLossR.rewrite = rewrite
      }
