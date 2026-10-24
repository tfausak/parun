module Parun.Codec.Chooser where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Chooser as Chooser

-- | Tagged rather than nullary-only, Parun.Codec.Pool's shape and for its reason:
-- one arm names a slot and so carries a payload, while Common.nullary IS
-- Common.tagged with no value, so the other two are unaffected.
codec :: Codec.Codec Chooser.Chooser
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "TheController" Chooser.TheController,
      Arm.nullary "EachInScope" Chooser.EachInScope,
      Arm.payload "BoundInSlot" SlotName.codec Chooser.BoundInSlot (\x -> case x of Chooser.BoundInSlot y -> Just y; _ -> Nothing)
    ]

tagOf :: Chooser.Chooser -> String
tagOf x = case x of
  Chooser.TheController {} -> "TheController"
  Chooser.EachInScope {} -> "EachInScope"
  Chooser.BoundInSlot {} -> "BoundInSlot"
