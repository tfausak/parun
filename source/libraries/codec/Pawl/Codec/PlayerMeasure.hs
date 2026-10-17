module Pawl.Codec.PlayerMeasure where

import qualified Pawl.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.PlayerMeasure as PlayerMeasure

codec :: Codec.Codec PlayerMeasure.PlayerMeasure
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "PermanentsControlled" PlayerMeasure.PermanentsControlled,
      Arm.payload "CountersOf" PlayerCounterKind.codec PlayerMeasure.CountersOf (\x -> case x of PlayerMeasure.CountersOf y -> Just y; _ -> Nothing)
    ]

tagOf :: PlayerMeasure.PlayerMeasure -> String
tagOf x = case x of
  PlayerMeasure.PermanentsControlled -> "PermanentsControlled"
  PlayerMeasure.CountersOf {} -> "CountersOf"
