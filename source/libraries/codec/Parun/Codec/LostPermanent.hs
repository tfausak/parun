module Parun.Codec.LostPermanent where

import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.LostPermanent as LostPermanent

codec :: Codec.Codec LostPermanent.LostPermanent
codec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Self" LostPermanent.Self,
      Arm.payload "Bound" SlotName.codec LostPermanent.Bound (\x -> case x of LostPermanent.Bound y -> Just y; _ -> Nothing)
    ]

tagOf :: LostPermanent.LostPermanent -> String
tagOf x = case x of
  LostPermanent.Self {} -> "Self"
  LostPermanent.Bound {} -> "Bound"
