{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ChooseNumber where

import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ChooseNumber as ChooseNumber
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation

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
