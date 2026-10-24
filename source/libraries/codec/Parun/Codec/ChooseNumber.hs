{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChooseNumber where

import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChooseNumber as ChooseNumber
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | The bound is ELIDED when absent, as Draw's slot is, and the chooser when it
-- is CR 608.2c's default, you.
codec :: Codec.Codec ChooseNumber.ChooseNumber
codec = Fields.object $ do
  slot <- Fields.required "slot" SlotName.codec ChooseNumber.slot
  upTo <- Fields.defaulted "upTo" Nothing (Common.maybe Common.natural) ChooseNumber.upTo
  chooser <- Fields.defaulted "chooser" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec ChooseNumber.chooser
  pure
    ChooseNumber.MkChooseNumber
      { ChooseNumber.slot = slot,
        ChooseNumber.upTo = upTo,
        ChooseNumber.chooser = chooser
      }
