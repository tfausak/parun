module Parun.Codec.SuspendCounters where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.SuspendCounters as SuspendCounters

-- | Tagged like Parun.Codec.Loyalty and for its reason: CR 107.3d's chosen X is a
-- wire value rather than a sentinel number the decoder would have to reserve.
codec :: Codec.Codec SuspendCounters.SuspendCounters
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Literal" Common.natural SuspendCounters.Literal (\x -> case x of SuspendCounters.Literal y -> Just y; _ -> Nothing),
      Arm.payload "Variable" Common.natural SuspendCounters.Variable (\x -> case x of SuspendCounters.Variable y -> Just y; _ -> Nothing)
    ]

tagOf :: SuspendCounters.SuspendCounters -> String
tagOf x = case x of
  SuspendCounters.Literal {} -> "Literal"
  SuspendCounters.Variable {} -> "Variable"
