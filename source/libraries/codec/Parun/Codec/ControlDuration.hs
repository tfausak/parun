module Parun.Codec.ControlDuration where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.ControlDuration as ControlDuration

codec :: Codec.Codec ControlDuration.ControlDuration
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "UntilTurnEnds" ControlDuration.UntilTurnEnds,
      Arm.nullary "UntilResolutionEnds" ControlDuration.UntilResolutionEnds,
      Arm.payload "WhileResolving" ObjectId.codec ControlDuration.WhileResolving (\x -> case x of ControlDuration.WhileResolving y -> Just y; _ -> Nothing),
      Arm.nullary "WhileSearching" ControlDuration.WhileSearching
    ]

tagOf :: ControlDuration.ControlDuration -> String
tagOf x = case x of
  ControlDuration.UntilTurnEnds -> "UntilTurnEnds"
  ControlDuration.UntilResolutionEnds -> "UntilResolutionEnds"
  ControlDuration.WhileResolving {} -> "WhileResolving"
  ControlDuration.WhileSearching -> "WhileSearching"
