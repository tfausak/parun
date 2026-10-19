module Pawl.Codec.DealtDamageToSpec where

import qualified Data.Text as Text
import qualified Pawl.Codec.DealtDamageTo as DealtDamageTo
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.DamageKind as DamageKind
import qualified Pawl.Types.DamagedParty as DamagedParty
import qualified Pawl.Types.DealtDamageTo as DealtDamageTo
import qualified Pawl.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.DealtDamageTo" $ do
  Spec.it s "any damage" $
    Common.assertCodec
      s
      DealtDamageTo.codec
      DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.Source, DealtDamageTo.kind = Nothing}
      " {\"party\":{\"type\":\"Source\"}} "
  Spec.it s "combat damage" $
    Common.assertCodec
      s
      DealtDamageTo.codec
      DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.InSlot (SlotName.MkSlotName (Text.pack "it")), DealtDamageTo.kind = Just DamageKind.Combat}
      " {\"party\":{\"type\":\"InSlot\",\"value\":\"it\"},\"kind\":{\"type\":\"Combat\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DealtDamageTo.codec
