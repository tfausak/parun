module Parun.Codec.ReturnPermanentsSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ReturnPermanents as ReturnPermanents
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ReturnPermanents as ReturnPermanents

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (ReturnPermanents.ReturnPermanents Keyword.Keyword)
codec = ReturnPermanents.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ReturnPermanents" $ do
  -- Meloku the Clouded Mirror's one land. The count is HOW MANY, matched
  -- exactly, Parun.Codec.TapPermanents' key names over a different action.
  Spec.it s "MkReturnPermanents" $
    Common.assertCodec
      s
      codec
      ( ReturnPermanents.MkReturnPermanents
          { ReturnPermanents.count = 1,
            ReturnPermanents.whichPermanents = Filter.HasCardType CardType.Land
          }
      )
      " {\"count\":1,\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
