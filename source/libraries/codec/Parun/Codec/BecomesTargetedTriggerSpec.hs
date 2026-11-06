module Parun.Codec.BecomesTargetedTriggerSpec where

import qualified Parun.Codec.BecomesTargetedTrigger as BecomesTargetedTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.BecomesTargetedTrigger as BecomesTargetedTrigger
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.TargetedSubject as TargetedSubject

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BecomesTargetedTrigger" $ do
  Spec.it s "writes no key for the defaults" $
    Common.assertCodec s BecomesTargetedTrigger.codec BecomesTargetedTrigger.defaultValue " {} "
  -- Ward's: only the relation narrowed.
  Spec.it s "round-trips a Self subject with an opponent's relation" $
    Common.assertCodec
      s
      BecomesTargetedTrigger.codec
      BecomesTargetedTrigger.defaultValue {BecomesTargetedTrigger.relation = PlayerRelation.Opponent}
      " {\"relation\":\"Opponent\"} "
  -- Leyline of Combustion's "you and/or" over Professor Hojo's creatures you
  -- control, an activated ability, one batch.
  Spec.it s "round-trips every field" $
    Common.assertCodec
      s
      BecomesTargetedTrigger.codec
      ( BecomesTargetedTrigger.MkBecomesTargetedTrigger
          { BecomesTargetedTrigger.subject = TargetedSubject.YouOrPermanent (ActingPermanent.Matching (Filter.And [Filter.HasCardType CardType.Creature, Filter.HeldBy Holder.Controller PlayerRelation.You])),
            BecomesTargetedTrigger.relation = PlayerRelation.Opponent,
            BecomesTargetedTrigger.kind = Just StackObjectKind.ActivatedAbility,
            BecomesTargetedTrigger.batching = Batching.OneOrMore
          }
      )
      " {\"subject\":{\"type\":\"YouOrPermanent\",\"value\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":\"Creature\"},{\"type\":\"HeldBy\",\"value\":{\"holder\":\"Controller\",\"relation\":\"You\"}}]}}},\"relation\":\"Opponent\",\"kind\":\"ActivatedAbility\",\"batching\":\"OneOrMore\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BecomesTargetedTrigger.codec
