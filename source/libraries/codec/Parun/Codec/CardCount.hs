module Parun.Codec.CardCount where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.CardCount as CardCount

codec :: Codec.Codec CardCount.CardCount
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Exactly" Common.natural CardCount.Exactly (\x -> case x of CardCount.Exactly y -> Just y; _ -> Nothing),
      Arm.nullary "Every" CardCount.Every
    ]

tagOf :: CardCount.CardCount -> String
tagOf x = case x of
  CardCount.Exactly {} -> "Exactly"
  CardCount.Every -> "Every"
