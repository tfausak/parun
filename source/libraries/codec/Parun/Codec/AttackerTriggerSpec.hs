module Parun.Codec.AttackerTriggerSpec where

import qualified Parun.Codec.AttackerTrigger as AttackerTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackCompany as AttackCompany
import qualified Parun.Types.AttackerTarget as AttackerTarget
import qualified Parun.Types.AttackerTrigger as AttackerTrigger
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackerTrigger" $ do
  -- Hanweir Garrison's "whenever this creature attacks".
  Spec.it s "the defaults write no key" $
    Common.assertCodec
      s
      AttackerTrigger.codec
      (AttackerTrigger.MkAttackerTrigger Filter.IsSource AttackerTarget.AnyTarget AttackCompany.AnyCompany TriggerFrequency.EveryTime Nothing)
      " {} "
  -- Every key away from its default, so a codec dropping any one would fail
  -- rather than round-trip the default.
  Spec.it s "every key writes itself" $
    Common.assertCodec
      s
      AttackerTrigger.codec
      ( AttackerTrigger.MkAttackerTrigger
          Filter.IsToken
          (AttackerTarget.Defending PlayerRelation.You)
          AttackCompany.Alone
          TriggerFrequency.FirstTimeEachTurn
          (Just (Condition.Compares (Compares.MkCompares (Quantity.Literal 0) Comparison.Exactly (Quantity.Literal 0))))
      )
      " {\"creature\":{\"type\":\"IsToken\"},\"target\":{\"type\":\"Defending\",\"value\":{\"type\":\"You\"}},\"company\":{\"type\":\"Alone\"},\"frequency\":{\"type\":\"FirstTimeEachTurn\"},\"while\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":0},\"comparison\":{\"type\":\"Exactly\"},\"threshold\":{\"type\":\"Literal\",\"value\":0}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackerTrigger.codec
