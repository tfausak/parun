module Parun.Codec.LifeTallySpec where

import qualified Parun.Codec.LifeTally as LifeTally
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.LifeTally as LifeTally
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.WhichTurn as WhichTurn

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeTally" $ do
  Spec.it s "this turn omits the turn" $
    Common.assertCodec
      s
      LifeTally.codec
      (LifeTally.MkLifeTally {LifeTally.player = PlayerRef.Relative PlayerRelation.You, LifeTally.direction = LifeDirection.Gained, LifeTally.turn = WhichTurn.ThisTurn})
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"direction\":{\"type\":\"Gained\"}} "
  Spec.it s "last turn" $
    Common.assertCodec
      s
      LifeTally.codec
      (LifeTally.MkLifeTally {LifeTally.player = PlayerRef.Candidate, LifeTally.direction = LifeDirection.Lost, LifeTally.turn = WhichTurn.LastTurn})
      " {\"player\":{\"type\":\"Candidate\"},\"direction\":{\"type\":\"Lost\"},\"turn\":{\"type\":\"LastTurn\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeTally.codec
