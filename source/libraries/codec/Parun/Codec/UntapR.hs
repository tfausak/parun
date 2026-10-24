{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.UntapR where

import qualified Parun.Codec.Phase as Phase
import qualified Parun.Codec.UntapRewrite as UntapRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.UntapR as UntapR

codec :: Codec.Codec UntapR.UntapR
codec = Fields.object $ do
  during <- Fields.defaulted "during" Nothing (Common.maybe Phase.codec) UntapR.during
  rewrite <- Fields.required "rewrite" UntapRewrite.codec UntapR.rewrite
  pure
    UntapR.MkUntapR
      { UntapR.during = during,
        UntapR.rewrite = rewrite
      }
