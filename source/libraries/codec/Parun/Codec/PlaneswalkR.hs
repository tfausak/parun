{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlaneswalkR where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.PlaneswalkCause as PlaneswalkCause
import qualified Parun.Codec.PlaneswalkRewrite as PlaneswalkRewrite
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlaneswalkR as PlaneswalkR

-- | The effect codec is a PARAMETER, Parun.Codec.DamageR's reason. Any cause is
-- the usual case, so the key is elided rather than written null.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (PlaneswalkR.PlaneswalkR effect)
codec effectCodec = Fields.object $ do
  whose <- Fields.required "whose" ControllerRelation.codec PlaneswalkR.whose
  cause <- Fields.defaulted "cause" Nothing (Common.maybe PlaneswalkCause.codec) PlaneswalkR.cause
  rewrite <- Fields.required "rewrite" (PlaneswalkRewrite.codec effectCodec) PlaneswalkR.rewrite
  pure
    PlaneswalkR.MkPlaneswalkR
      { PlaneswalkR.whose = whose,
        PlaneswalkR.cause = cause,
        PlaneswalkR.rewrite = rewrite
      }
