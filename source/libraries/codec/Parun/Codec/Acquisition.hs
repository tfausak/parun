module Parun.Codec.Acquisition where

import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Acquisition as Acquisition

codec :: Codec.Codec Acquisition.Acquisition
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Own" Acquisition.Own,
      Arm.payload "Copied" Timestamp.codec Acquisition.Copied (\x -> case x of Acquisition.Copied y -> Just y; _ -> Nothing)
    ]

tagOf :: Acquisition.Acquisition -> String
tagOf x = case x of
  Acquisition.Own {} -> "Own"
  Acquisition.Copied {} -> "Copied"
