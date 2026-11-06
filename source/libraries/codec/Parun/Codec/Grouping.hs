module Parun.Codec.Grouping where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.Grouping as Grouping

codec :: Codec.Codec Grouping.Grouping
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Sectors" Grouping.Sectors,
      Arm.payload "Piles" (Common.nonEmpty SlotName.codec) Grouping.Piles (\x -> case x of Grouping.Piles y -> Just y; _ -> Nothing)
    ]

tagOf :: Grouping.Grouping -> String
tagOf x = case x of
  Grouping.Sectors -> "Sectors"
  Grouping.Piles {} -> "Piles"
