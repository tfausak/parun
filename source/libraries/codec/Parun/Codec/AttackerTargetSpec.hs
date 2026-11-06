module Parun.Codec.AttackerTargetSpec where

import qualified Parun.Codec.AttackerTarget as AttackerTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackerTarget as AttackerTarget
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackerTarget" $ do
  Spec.it s "AnyTarget" $
    Common.assertCodec s AttackerTarget.codec AttackerTarget.AnyTarget " {\"type\":\"AnyTarget\"} "
  Spec.it s "Defending" $
    Common.assertCodec s AttackerTarget.codec (AttackerTarget.Defending PlayerRelation.You) " {\"type\":\"Defending\",\"value\":\"You\"} "
  Spec.it s "Permanent" $
    Common.assertCodec s AttackerTarget.codec (AttackerTarget.Permanent (Filter.HasCardType CardType.Battle)) " {\"type\":\"Permanent\",\"value\":{\"type\":\"HasCardType\",\"value\":\"Battle\"}} "
  Spec.it s "PlayerWithMostLife" $
    Common.assertCodec s AttackerTarget.codec AttackerTarget.PlayerWithMostLife " {\"type\":\"PlayerWithMostLife\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackerTarget.codec
