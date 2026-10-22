module Pawl.Codec.LifeGainRewrite where

import qualified Pawl.Codec.Scaling as Scaling
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.LifeGainRewrite as LifeGainRewrite

codec :: Codec.Codec LifeGainRewrite.LifeGainRewrite
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Scaled" Scaling.codec LifeGainRewrite.Scaled (\x -> case x of LifeGainRewrite.Scaled y -> Just y; _ -> Nothing),
      Arm.nullary "DrawInstead" LifeGainRewrite.DrawInstead
    ]

tagOf :: LifeGainRewrite.LifeGainRewrite -> String
tagOf x = case x of
  LifeGainRewrite.Scaled {} -> "Scaled"
  LifeGainRewrite.DrawInstead -> "DrawInstead"
