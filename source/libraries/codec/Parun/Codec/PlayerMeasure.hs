module Parun.Codec.PlayerMeasure where

import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.PlayerMeasure as PlayerMeasure

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
