module Parun.Codec.AttackedPlayerSpec where

import qualified Parun.Codec.AttackedPlayer as AttackedPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackedPlayer as AttackedPlayer
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackedPlayer" $ do
  Spec.it s "Related" $
    Common.assertCodec s AttackedPlayer.codec (AttackedPlayer.Related PlayerRelation.You) " {\"type\":\"Related\",\"value\":{\"type\":\"You\"}} "
  Spec.it s "Enchanted" $
    Common.assertCodec s AttackedPlayer.codec AttackedPlayer.Enchanted " {\"type\":\"Enchanted\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackedPlayer.codec
