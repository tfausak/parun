module Parun.Codec.ObjectCount where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.ObjectCount as ObjectCount

-- | Flat over the nesting: Parun.Codec.CostAmount's two tags for Exactly, so a
-- count reads the same here as in a component carrying a bare CostAmount, and
-- a third for Every.
codec :: Codec.Codec ObjectCount.ObjectCount
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Fixed" Common.natural (ObjectCount.Exactly . CostAmount.Fixed) (\x -> case x of ObjectCount.Exactly (CostAmount.Fixed y) -> Just y; _ -> Nothing),
      Arm.payload "Announced" SlotName.codec (ObjectCount.Exactly . CostAmount.Announced) (\x -> case x of ObjectCount.Exactly (CostAmount.Announced y) -> Just y; _ -> Nothing),
      Arm.nullary "Every" ObjectCount.Every
    ]

tagOf :: ObjectCount.ObjectCount -> String
tagOf x = case x of
  ObjectCount.Exactly (CostAmount.Fixed {}) -> "Fixed"
  ObjectCount.Exactly (CostAmount.Announced {}) -> "Announced"
  ObjectCount.Every -> "Every"
