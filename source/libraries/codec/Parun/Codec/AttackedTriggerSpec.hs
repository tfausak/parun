module Parun.Codec.AttackedTriggerSpec where

import qualified Parun.Codec.AttackedTrigger as AttackedTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackedSubject as AttackedSubject
import qualified Parun.Types.AttackedTrigger as AttackedTrigger
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackedTrigger" $ do
  -- Lulu, Stern Guardian's "whenever an opponent attacks you": the two keys hold
  -- DIFFERENT relations, so a codec that crossed them would not round-trip.
  Spec.it s "an attacker and an attacked subject" $
    Common.assertCodec
      s
      AttackedTrigger.codec
      (AttackedTrigger.MkAttackedTrigger (Just PlayerRelation.Opponent) (AttackedSubject.Related PlayerRelation.You))
      " {\"attacker\":\"Opponent\",\"attacked\":{\"type\":\"Related\",\"value\":\"You\"}} "
  -- Curse of Vitality's "whenever enchanted player is attacked".
  Spec.it s "no attacker writes no key" $
    Common.assertCodec
      s
      AttackedTrigger.codec
      (AttackedTrigger.MkAttackedTrigger Nothing AttackedSubject.Enchanted)
      " {\"attacked\":{\"type\":\"Enchanted\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackedTrigger.codec
