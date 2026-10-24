module Parun.Codec.Anchor where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.Anchor as Anchor

codec :: Codec.Codec Anchor.Anchor
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Bound" SlotName.codec Anchor.Bound (\x -> case x of Anchor.Bound y -> Just y; _ -> Nothing),
      Arm.nullary "Evaluated" Anchor.Evaluated
    ]

tagOf :: Anchor.Anchor -> String
tagOf x = case x of
  Anchor.Bound {} -> "Bound"
  Anchor.Evaluated {} -> "Evaluated"
