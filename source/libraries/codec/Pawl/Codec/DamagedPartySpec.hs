module Pawl.Codec.DamagedPartySpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.DamagedParty as DamagedParty
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.DamagedParty as DamagedParty
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.DamagedParty" $ do
  Spec.it s "Related" $
    Common.assertCodec s DamagedParty.codec (DamagedParty.Related PlayerRelation.You) " {\"type\":\"Related\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "Source" $
    Common.assertCodec s DamagedParty.codec DamagedParty.Source " {\"type\":\"Source\"} "
  Spec.it s "InSlot" $
    Common.assertCodec s DamagedParty.codec (DamagedParty.InSlot (SlotName.MkSlotName (Text.pack "thatDepartedPermanent"))) " {\"type\":\"InSlot\",\"value\":\"thatDepartedPermanent\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DamagedParty.codec
