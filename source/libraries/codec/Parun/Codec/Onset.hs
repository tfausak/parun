module Parun.Codec.Onset where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Onset as Onset

codec :: Codec.Codec Onset.Onset
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Immediately" Onset.Immediately,
      Arm.payload "FromNextTurnOf" PlayerRef.codec Onset.FromNextTurnOf (\x -> case x of Onset.FromNextTurnOf y -> Just y; _ -> Nothing),
      Arm.nullary "FromThatExtraTurn" Onset.FromThatExtraTurn
    ]

tagOf :: Onset.Onset -> String
tagOf x = case x of
  Onset.Immediately {} -> "Immediately"
  Onset.FromNextTurnOf {} -> "FromNextTurnOf"
  Onset.FromThatExtraTurn {} -> "FromThatExtraTurn"
