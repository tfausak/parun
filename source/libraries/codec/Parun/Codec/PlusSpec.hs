module Parun.Codec.PlusSpec where

import qualified Parun.Codec.Plus as Plus
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Plus as Plus
import qualified Parun.Types.Quantity as Quantity

-- | Instantiated at 'Quantity.Quantity', the only concrete instantiation
-- anywhere: 'Parun.Codec.Quantity' passes its own recursive codec in.
codec :: Codec.Codec (Plus.Plus Quantity.Quantity)
codec = Plus.codec Quantity.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Plus" $ do
  -- CR 208.2: a printed 1+*. Asymmetric on purpose -- both halves are a Quantity, so a swapped codec would round-trip an equal pair.
  Spec.it s "MkPlus" $
    Common.assertCodec
      s
      codec
      ( Plus.MkPlus
          { Plus.left = Quantity.Literal 1,
            Plus.right = Quantity.Star
          }
      )
      " {\"left\":{\"type\":\"Literal\",\"value\":1},\"right\":{\"type\":\"Star\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
