module Parun.Codec.DevourCount where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.DevourCount as DevourCount

-- | Tagged rather than a bare number, because CR 702.82b's restated N (Thromok
-- the Insatiable) carries no number at all and a bare number could not say so.
codec :: Codec.Codec DevourCount.DevourCount
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Fixed" Common.natural DevourCount.Fixed (\x -> case x of DevourCount.Fixed y -> Just y; _ -> Nothing),
      Arm.nullary "Devoured" DevourCount.Devoured
    ]

tagOf :: DevourCount.DevourCount -> String
tagOf x = case x of
  DevourCount.Fixed {} -> "Fixed"
  DevourCount.Devoured {} -> "Devoured"
