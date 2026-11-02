module Parun.Codec.DealsDamageToPermanentSpec where

import qualified Parun.Codec.DealsDamageToPermanent as DealsDamageToPermanent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DamageKind as DamageKind
import qualified Parun.Types.DealsDamageToPermanent as DealsDamageToPermanent
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DealsDamageToPermanent" $ do
  Spec.it s "MkDealsDamageToPermanent, every key" $
    Common.assertCodec
      s
      DealsDamageToPermanent.codec
      ( DealsDamageToPermanent.MkDealsDamageToPermanent
          { DealsDamageToPermanent.actor = ActingPermanent.Matching (Filter.HasAttached Filter.IsSource),
            DealsDamageToPermanent.recipient = CardType.Planeswalker,
            DealsDamageToPermanent.kind = Just DamageKind.Combat
          }
      )
      " {\"actor\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasAttached\",\"value\":{\"type\":\"IsSource\"}}},\"recipient\":{\"type\":\"Planeswalker\"},\"kind\":{\"type\":\"Combat\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DealsDamageToPermanent.codec
