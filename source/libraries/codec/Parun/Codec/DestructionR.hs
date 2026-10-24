{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DestructionR where

import qualified Parun.Codec.DestructionRewrite as DestructionRewrite
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DestructionR as DestructionR

codec :: Codec.Codec DestructionR.DestructionR
codec = Fields.object $ do
  matching <- Fields.defaulted "matching" Nothing (Common.maybe (Filter.codec Keyword.codec)) DestructionR.matching
  rewrite <- Fields.required "rewrite" DestructionRewrite.codec DestructionR.rewrite
  pure
    DestructionR.MkDestructionR
      { DestructionR.matching = matching,
        DestructionR.rewrite = rewrite
      }
