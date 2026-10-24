module Parun.Codec.PlayBudgetSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.PlayBudget as PlayBudget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayBudget as PlayBudget

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayBudget" $ do
  Spec.it s "March of Reckless Joy's two plays over three cards" $
    Common.assertCodec
      s
      PlayBudget.codec
      PlayBudget.MkPlayBudget
        { PlayBudget.remaining = 2,
          PlayBudget.covers = Set.fromList (fmap ObjectId.MkObjectId [4, 5, 6])
        }
      " {\"remaining\":2,\"covers\":[4,5,6]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayBudget.codec
