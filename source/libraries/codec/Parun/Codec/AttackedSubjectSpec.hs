module Parun.Codec.AttackedSubjectSpec where

import qualified Parun.Codec.AttackedSubject as AttackedSubject
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackedSubject as AttackedSubject
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackedSubject" $ do
  Spec.it s "Related" $
    Common.assertCodec s AttackedSubject.codec (AttackedSubject.Related PlayerRelation.You) " {\"type\":\"Related\",\"value\":\"You\"} "
  Spec.it s "Enchanted" $
    Common.assertCodec s AttackedSubject.codec AttackedSubject.Enchanted " {\"type\":\"Enchanted\"} "
  Spec.it s "Source" $
    Common.assertCodec s AttackedSubject.codec AttackedSubject.Source " {\"type\":\"Source\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackedSubject.codec
