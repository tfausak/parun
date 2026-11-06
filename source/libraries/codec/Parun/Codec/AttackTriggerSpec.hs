module Parun.Codec.AttackTriggerSpec where

import qualified Parun.Codec.AttackTrigger as AttackTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackCompany as AttackCompany
import qualified Parun.Types.AttackTrigger as AttackTrigger
import qualified Parun.Types.AttackedSubject as AttackedSubject
import qualified Parun.Types.AttackedTrigger as AttackedTrigger
import qualified Parun.Types.AttackerTarget as AttackerTarget
import qualified Parun.Types.AttackerTrigger as AttackerTrigger
import qualified Parun.Types.DeclarationTrigger as DeclarationTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequency

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackTrigger" $ do
  Spec.it s "Attacker" $
    Common.assertCodec
      s
      AttackTrigger.codec
      (AttackTrigger.Attacker (AttackerTrigger.MkAttackerTrigger Filter.IsSource AttackerTarget.AnyTarget AttackCompany.AnyCompany TriggerFrequency.EveryTime Nothing))
      " {\"type\":\"Attacker\",\"value\":{}} "
  Spec.it s "Attacked" $
    Common.assertCodec
      s
      AttackTrigger.codec
      (AttackTrigger.Attacked (AttackedTrigger.MkAttackedTrigger Nothing AttackedSubject.Source))
      " {\"type\":\"Attacked\",\"value\":{\"attacked\":{\"type\":\"Source\"}}} "
  Spec.it s "Declaration" $
    Common.assertCodec
      s
      AttackTrigger.codec
      (AttackTrigger.Declaration (DeclarationTrigger.MkDeclarationTrigger PlayerRelation.AnyPlayer Nothing))
      " {\"type\":\"Declaration\",\"value\":{\"player\":\"AnyPlayer\"}} "
  Spec.it s "Unblocked" $
    Common.assertCodec
      s
      AttackTrigger.codec
      (AttackTrigger.Unblocked Filter.IsSource)
      " {\"type\":\"Unblocked\",\"value\":{\"type\":\"IsSource\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackTrigger.codec
