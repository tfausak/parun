module Parun.Codec.CrewRole where

import qualified Parun.Codec.TriggerFrequency as TriggerFrequency
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.CrewRole as CrewRole

codec :: Codec.Codec CrewRole.CrewRole
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Vehicle" TriggerFrequency.codec CrewRole.Vehicle (\x -> case x of CrewRole.Vehicle y -> Just y; _ -> Nothing),
      Arm.nullary "Crewer" CrewRole.Crewer
    ]

tagOf :: CrewRole.CrewRole -> String
tagOf x = case x of
  CrewRole.Vehicle {} -> "Vehicle"
  CrewRole.Crewer {} -> "Crewer"
