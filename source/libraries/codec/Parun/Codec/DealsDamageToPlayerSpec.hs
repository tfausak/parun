module Parun.Codec.DealsDamageToPlayerSpec where

import qualified Parun.Codec.DealsDamageToPlayer as DealsDamageToPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.DealsDamageToPlayer as DealsDamageToPlayer
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DealsDamageToPlayer" $ do
  Spec.it s "MkDealsDamageToPlayer, both keys" $
    Common.assertCodec
      s
      DealsDamageToPlayer.codec
      ( DealsDamageToPlayer.MkDealsDamageToPlayer
          { DealsDamageToPlayer.actor = ActingPermanent.Matching (Filter.HasAttached Filter.IsSource),
            DealsDamageToPlayer.recipient = PlayerRelation.Opponent
          }
      )
      " {\"actor\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasAttached\",\"value\":{\"type\":\"IsSource\"}}},\"recipient\":{\"type\":\"Opponent\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s DealsDamageToPlayer.codec
