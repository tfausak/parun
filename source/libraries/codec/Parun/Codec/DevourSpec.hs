module Parun.Codec.DevourSpec where

import qualified Parun.Codec.Devour as Devour
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Devour as Devour
import qualified Parun.Types.DevourCount as DevourCount
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Devour.Devour Keyword.Keyword)
codec = Devour.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Devour" $ do
  -- CR 702.82a: devour 3 (Thunder-Thrash Elder), whose "creatures" is the rule's
  -- rather than the card's, so no quality is written.
  Spec.it s "MkDevour, no quality" $
    Common.assertCodec
      s
      codec
      (Devour.MkDevour {Devour.quality = Nothing, Devour.count = DevourCount.Fixed 3})
      " {\"count\":{\"type\":\"Fixed\",\"value\":3}} "
  -- CR 702.82c: devour artifact 1 (Caprichrome).
  Spec.it s "MkDevour, a quality" $
    Common.assertCodec
      s
      codec
      (Devour.MkDevour {Devour.quality = Just (Filter.HasCardType CardType.Artifact), Devour.count = DevourCount.Fixed 1})
      " {\"count\":{\"type\":\"Fixed\",\"value\":1},\"quality\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Artifact\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
