{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Divide where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Divide as Divide
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | The chooser is ELIDED when it is CR 608.2c's default, you.
codec :: Codec.Codec Divide.Divide
codec = Fields.object $ do
  quantity <- Fields.required "quantity" Quantity.codec Divide.quantity
  among <- Fields.required "among" ObjectRef.codec Divide.among
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec Divide.chooser
  slot <- Fields.required "slot" SlotName.codec Divide.slot
  pure
    Divide.MkDivide
      { Divide.quantity = quantity,
        Divide.among = among,
        Divide.chooser = chooser,
        Divide.slot = slot
      }
