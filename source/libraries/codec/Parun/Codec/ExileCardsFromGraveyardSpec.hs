module Parun.Codec.ExileCardsFromGraveyardSpec where

import qualified Parun.Codec.ExileCardsFromGraveyard as ExileCardsFromGraveyard
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ExileCardsFromGraveyard as ExileCardsFromGraveyard
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (ExileCardsFromGraveyard.ExileCardsFromGraveyard Keyword.Keyword)
codec = ExileCardsFromGraveyard.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExileCardsFromGraveyard" $ do
  -- CR 406.2 as a cost: Headless Skaab exiles one creature card from your graveyard.
  Spec.it s "MkExileCardsFromGraveyard" $
    Common.assertCodec
      s
      codec
      ( ExileCardsFromGraveyard.MkExileCardsFromGraveyard
          { ExileCardsFromGraveyard.count = 1,
            ExileCardsFromGraveyard.whichCards = Filter.HasCardType CardType.Creature
          }
      )
      " {\"count\":1,\"whichCards\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
