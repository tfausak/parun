module Parun.Codec.ControlMargin where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ControlMargin as ControlMargin

-- | Natural rather than an integer, so a negative margin is rejected at decode.
codec :: Codec.Codec ControlMargin.ControlMargin
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "AtLeast" Common.natural ControlMargin.AtLeast (\x -> case x of ControlMargin.AtLeast y -> Just y; _ -> Nothing),
      Arm.payload "MoreThanYou" Common.natural ControlMargin.MoreThanYou (\x -> case x of ControlMargin.MoreThanYou y -> Just y; _ -> Nothing)
    ]

tagOf :: ControlMargin.ControlMargin -> String
tagOf x = case x of
  ControlMargin.AtLeast {} -> "AtLeast"
  ControlMargin.MoreThanYou {} -> "MoreThanYou"
