module Parun.Codec.AttackTargetSpec where

import qualified Parun.Codec.AttackTarget as AttackTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackTarget as AttackTarget
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackTarget" $ do
  Spec.it s "OfPlayer" $
    Common.assertCodec
      s
      AttackTarget.codec
      (AttackTarget.OfPlayer (PlayerId.MkPlayerId 1))
      " {\"type\":\"OfPlayer\",\"value\":1} "
  -- CR 306.6 and CR 310.5 name a PERMANENT where the arm above names a player, so
  -- the two carry different id types and each gets a case.
  Spec.it s "OfPlaneswalker" $
    Common.assertCodec
      s
      AttackTarget.codec
      (AttackTarget.OfPlaneswalker (ObjectId.MkObjectId 2))
      " {\"type\":\"OfPlaneswalker\",\"value\":2} "
  Spec.it s "OfBattle" $
    Common.assertCodec
      s
      AttackTarget.codec
      (AttackTarget.OfBattle (ObjectId.MkObjectId 3))
      " {\"type\":\"OfBattle\",\"value\":3} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackTarget.codec
