module Parun.Codec.ActivationsThisTurnSpec where

import qualified Parun.Codec.ActivationsThisTurn as ActivationsThisTurn
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActivationCriteria as ActivationCriteria
import qualified Parun.Types.ActivationsThisTurn as ActivationsThisTurn
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActivationsThisTurn" $ do
  Spec.it s "empty criteria encode as an empty object" $
    Common.assertCodec
      s
      ActivationsThisTurn.codec
      ( ActivationsThisTurn.MkActivationsThisTurn
          { ActivationsThisTurn.activator = PlayerRef.Relative PlayerRelation.You,
            ActivationsThisTurn.source = Filter.And [],
            ActivationsThisTurn.criteria = ActivationCriteria.MkActivationCriteria {ActivationCriteria.grantedBy = Nothing, ActivationCriteria.whichKind = Nothing, ActivationCriteria.whichLoyalty = Nothing}
          }
      )
      " {\"activator\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"source\":{\"type\":\"And\",\"value\":[]},\"criteria\":{}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ActivationsThisTurn.codec
