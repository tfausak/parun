module Parun.Codec.LeavesTriggerSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.LeavesTrigger as LeavesTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.LeavesTrigger as LeavesTrigger
import qualified Parun.Types.LeavingPermanent as LeavingPermanent
import qualified Parun.Types.OwnedZone as OwnedZone
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LeavesTrigger" $ do
  Spec.it s "writes no key for the defaults" $
    Common.assertCodec s LeavesTrigger.codec LeavesTrigger.defaultValue " {} "
  Spec.it s "round-trips a destination" $
    Common.assertCodec
      s
      LeavesTrigger.codec
      (LeavesTrigger.dies LeavingPermanent.Self)
      " {\"destinations\":[{\"zone\":\"Graveyard\"}]} "
  Spec.it s "round-trips an owned destination" $
    Common.assertCodec
      s
      LeavesTrigger.codec
      LeavesTrigger.defaultValue {LeavesTrigger.destinations = Set.singleton (OwnedZone.MkOwnedZone Zone.Graveyard PlayerRelation.You)}
      " {\"destinations\":[{\"owner\":\"You\",\"zone\":\"Graveyard\"}]} "
  Spec.it s "round-trips every field" $
    Common.assertCodec
      s
      LeavesTrigger.codec
      (LeavesTrigger.MkLeavesTrigger (LeavingPermanent.Matching (Filter.Not (Filter.HasCardType CardType.Creature))) (Set.singleton (OwnedZone.MkOwnedZone Zone.Hand PlayerRelation.AnyPlayer)) Batching.OneOrMore)
      " {\"batching\":\"OneOrMore\",\"destinations\":[{\"zone\":\"Hand\"}],\"permanent\":{\"type\":\"Matching\",\"value\":{\"type\":\"Not\",\"value\":{\"type\":\"HasCardType\",\"value\":\"Creature\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LeavesTrigger.codec
