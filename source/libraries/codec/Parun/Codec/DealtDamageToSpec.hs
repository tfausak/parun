module Parun.Codec.DealtDamageToSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.DealtDamageTo as DealtDamageTo
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.DamageDealer as DamageDealer
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DamagedParty as DamagedParty
import qualified Parun.Types.DealtDamageTo as DealtDamageTo
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.Lookback as Lookback
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DealtDamageTo" $ do
  Spec.it s "any damage" $
    Common.assertCodec
      s
      DealtDamageTo.codec
      DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.Source, DealtDamageTo.kind = Nothing, DealtDamageTo.window = Lookback.ThisTurn, DealtDamageTo.dealer = DamageDealer.Candidate}
      " {\"party\":{\"type\":\"Source\"}} "
  Spec.it s "combat damage" $
    Common.assertCodec
      s
      DealtDamageTo.codec
      DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.InSlot (SlotName.MkSlotName (Text.pack "it")), DealtDamageTo.kind = Just DamageKind.Combat, DealtDamageTo.window = Lookback.ThisTurn, DealtDamageTo.dealer = DamageDealer.Candidate}
      " {\"party\":{\"type\":\"InSlot\",\"value\":\"it\"},\"kind\":{\"type\":\"Combat\"}} "
  Spec.it s "anyone, as this object" $
    Common.assertCodec
      s
      DealtDamageTo.codec
      DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.Anyone, DealtDamageTo.kind = Nothing, DealtDamageTo.window = Lookback.AsThisObject, DealtDamageTo.dealer = DamageDealer.Candidate}
      " {\"party\":{\"type\":\"Anyone\"},\"window\":{\"type\":\"AsThisObject\"}} "
  Spec.it s "the source's combat damage to the candidate's controller" $
    Common.assertCodec
      s
      DealtDamageTo.codec
      DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = DamagedParty.HolderOfCandidate Holder.Controller, DealtDamageTo.kind = Just DamageKind.Combat, DealtDamageTo.window = Lookback.ThisTurn, DealtDamageTo.dealer = DamageDealer.Source}
      " {\"party\":{\"type\":\"HolderOfCandidate\",\"value\":{\"type\":\"Controller\"}},\"kind\":{\"type\":\"Combat\"},\"dealer\":{\"type\":\"Source\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DealtDamageTo.codec
