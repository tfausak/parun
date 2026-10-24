module Parun.Codec.LifeLossRewrite where

import qualified Parun.Codec.Scaling as Scaling
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.LifeLossRewrite as LifeLossRewrite

codec :: Codec.Codec LifeLossRewrite.LifeLossRewrite
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "LeaveAtLeast" Common.natural LifeLossRewrite.LeaveAtLeast (\x -> case x of LifeLossRewrite.LeaveAtLeast y -> Just y; _ -> Nothing),
      Arm.payload "Scaled" Scaling.codec LifeLossRewrite.Scaled (\x -> case x of LifeLossRewrite.Scaled y -> Just y; _ -> Nothing),
      Arm.nullary "ExileFromTopOfYourLibrary" LifeLossRewrite.ExileFromTopOfYourLibrary,
      Arm.nullary "GainInstead" LifeLossRewrite.GainInstead
    ]

tagOf :: LifeLossRewrite.LifeLossRewrite -> String
tagOf x = case x of
  LifeLossRewrite.LeaveAtLeast {} -> "LeaveAtLeast"
  LifeLossRewrite.Scaled {} -> "Scaled"
  LifeLossRewrite.ExileFromTopOfYourLibrary {} -> "ExileFromTopOfYourLibrary"
  LifeLossRewrite.GainInstead {} -> "GainInstead"
