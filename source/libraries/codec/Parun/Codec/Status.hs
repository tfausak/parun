module Parun.Codec.Status where

import qualified Parun.Codec.Departure as Departure
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Status as Status

codec :: Codec.Codec Status.Status
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Playing" Status.Playing,
      Arm.payload "Departed" Departure.codec Status.Departed (\x -> case x of Status.Departed y -> Just y; _ -> Nothing)
    ]

tagOf :: Status.Status -> String
tagOf x = case x of
  Status.Playing {} -> "Playing"
  Status.Departed {} -> "Departed"
