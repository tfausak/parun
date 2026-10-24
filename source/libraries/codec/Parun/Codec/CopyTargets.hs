module Parun.Codec.CopyTargets where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CopyTargets as CopyTargets

-- | Tagged rather than an enum: CR 707.10d's and CR 707.10e's arms carry refs
-- naming their candidates, where the other two carry nothing.
codec :: Codec.Codec CopyTargets.CopyTargets
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Copied" CopyTargets.Copied,
      Arm.nullary "ChosenByController" CopyTargets.ChosenByController,
      Arm.payload "ForEach" (Common.nonEmpty ObjectRef.codec) CopyTargets.ForEach (\x -> case x of CopyTargets.ForEach y -> Just y; _ -> Nothing),
      Arm.payload "Stated" ObjectRef.codec CopyTargets.Stated (\x -> case x of CopyTargets.Stated y -> Just y; _ -> Nothing)
    ]

tagOf :: CopyTargets.CopyTargets -> String
tagOf x = case x of
  CopyTargets.Copied {} -> "Copied"
  CopyTargets.ChosenByController {} -> "ChosenByController"
  CopyTargets.ForEach {} -> "ForEach"
  CopyTargets.Stated {} -> "Stated"
