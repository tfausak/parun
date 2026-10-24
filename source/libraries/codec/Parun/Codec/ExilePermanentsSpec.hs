module Parun.Codec.ExilePermanentsSpec where

import qualified Parun.Codec.ExilePermanents as ExilePermanents
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ExilePermanents as ExilePermanents
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (ExilePermanents.ExilePermanents Keyword.Keyword)
codec = ExilePermanents.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExilePermanents" $ do
  -- Food Chain's one creature. The count is HOW MANY, matched
  -- exactly, Parun.Codec.TapPermanents' key names over a different action.
  Spec.it s "MkExilePermanents" $
    Common.assertCodec
      s
      codec
      ( ExilePermanents.MkExilePermanents
          { ExilePermanents.count = 1,
            ExilePermanents.whichPermanents = Filter.HasCardType CardType.Creature
          }
      )
      " {\"count\":1,\"whichPermanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
