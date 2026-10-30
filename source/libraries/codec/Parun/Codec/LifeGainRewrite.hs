module Parun.Codec.LifeGainRewrite where

import qualified Parun.Codec.Scaling as Scaling
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LifeGainRewrite as LifeGainRewrite

codec :: Codec.Codec LifeGainRewrite.LifeGainRewrite
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Scaled" Scaling.codec LifeGainRewrite.Scaled (\x -> case x of LifeGainRewrite.Scaled y -> Just y; _ -> Nothing),
      Arm.nullary "DrawInstead" LifeGainRewrite.DrawInstead,
      Arm.nullary "LoseInstead" LifeGainRewrite.LoseInstead
    ]

tagOf :: LifeGainRewrite.LifeGainRewrite -> String
tagOf x = case x of
  LifeGainRewrite.Scaled {} -> "Scaled"
  LifeGainRewrite.DrawInstead -> "DrawInstead"
  LifeGainRewrite.LoseInstead -> "LoseInstead"
