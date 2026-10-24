module Parun.Codec.ActingPermanentSpec where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActingPermanent" $ do
  Spec.it s "Self" $
    Common.assertCodec
      s
      ActingPermanent.codec
      ActingPermanent.Self
      " {\"type\":\"Self\"} "
  Spec.it s "Matching" $
    Common.assertCodec
      s
      ActingPermanent.codec
      (ActingPermanent.Matching (Filter.ControlledBy PlayerRelation.You))
      " {\"type\":\"Matching\",\"value\":{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActingPermanent.codec
