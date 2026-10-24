module Parun.Codec.IfTaken where

import qualified Parun.Codec.ClauseIndex as ClauseIndex
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.IfTaken as IfTaken

codec :: Codec.Codec IfTaken.IfTaken
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "AnyTaken" (Common.nonEmpty ClauseIndex.codec) IfTaken.AnyTaken (\x -> case x of IfTaken.AnyTaken y -> Just y; _ -> Nothing),
      Arm.payload "NoneTaken" (Common.nonEmpty ClauseIndex.codec) IfTaken.NoneTaken (\x -> case x of IfTaken.NoneTaken y -> Just y; _ -> Nothing),
      Arm.payload "Couldnt" (Common.nonEmpty ClauseIndex.codec) IfTaken.Couldnt (\x -> case x of IfTaken.Couldnt y -> Just y; _ -> Nothing)
    ]

tagOf :: IfTaken.IfTaken -> String
tagOf x = case x of
  IfTaken.AnyTaken {} -> "AnyTaken"
  IfTaken.NoneTaken {} -> "NoneTaken"
  IfTaken.Couldnt {} -> "Couldnt"
