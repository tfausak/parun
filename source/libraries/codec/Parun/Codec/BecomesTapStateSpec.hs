module Parun.Codec.BecomesTapStateSpec where

import qualified Parun.Codec.BecomesTapState as BecomesTapState
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.BecomesTapState as BecomesTapState
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Holder as Holder
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TapState as TapState

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BecomesTapState" $ do
  Spec.it s "MkBecomesTapState, both keys" $
    Common.assertCodec
      s
      BecomesTapState.codec
      ( BecomesTapState.MkBecomesTapState
          { BecomesTapState.status = TapState.Untapped,
            BecomesTapState.actor = ActingPermanent.Matching (Filter.HeldBy Holder.Controller PlayerRelation.You)
          }
      )
      " {\"actor\":{\"type\":\"Matching\",\"value\":{\"type\":\"HeldBy\",\"value\":{\"holder\":{\"type\":\"Controller\"},\"relation\":{\"type\":\"You\"}}}},\"status\":{\"type\":\"Untapped\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BecomesTapState.codec
