module Parun.Codec.DealtDamageToSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.DealtDamageTo as DealtDamageTo
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagedParty as DamagedParty
import qualified Parun.Types.DealtDamageTo as DealtDamageTo
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DealtDamageTo" $ do
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
