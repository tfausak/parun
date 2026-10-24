module Parun.Codec.PlayerQuantitySpec where

import qualified Parun.Codec.PlayerQuantity as PlayerQuantity
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerQuantity as PlayerQuantity
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerQuantity" $ do
  -- Both keys are required: this payload has no optional part, which is what
  -- makes it shareable at all. An arm needing anything else spins out its own
  -- record rather than adding a nullable key here -- see Parun.Types.Mill.
  Spec.it s "MkPlayerQuantity, both keys written" $
    Common.assertCodec
      s
      PlayerQuantity.codec
      (PlayerQuantity.MkPlayerQuantity (PlayerRef.Relative PlayerRelation.You) (Quantity.Literal 2))
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"quantity\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PlayerQuantity.codec
