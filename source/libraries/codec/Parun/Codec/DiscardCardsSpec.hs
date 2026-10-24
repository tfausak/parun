module Parun.Codec.DiscardCardsSpec where

import qualified Parun.Codec.DiscardCards as DiscardCards
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardCount as CardCount
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (DiscardCards.DiscardCards Keyword.Keyword)
codec = DiscardCards.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.DiscardCards" $ do
  -- CR 601.2f as a cost that names a quality: Magmatic Insight discards one
  -- land card.
  Spec.it s "MkDiscardCards, a filter that names a quality" $
    Common.assertCodec
      s
      codec
      ( DiscardCards.MkDiscardCards
          { DiscardCards.count = CardCount.Exactly 1,
            DiscardCards.whichCards = Filter.HasCardType CardType.Land
          }
      )
      " {\"count\":{\"type\":\"Exactly\",\"value\":1},\"whichCards\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}} "
  -- Cathartic Reunion's "discard two cards", which names none.
  Spec.it s "MkDiscardCards, a filter that admits everything" $
    Common.assertCodec
      s
      codec
      ( DiscardCards.MkDiscardCards
          { DiscardCards.count = CardCount.Exactly 2,
            DiscardCards.whichCards = Filter.And []
          }
      )
      " {\"count\":{\"type\":\"Exactly\",\"value\":2},\"whichCards\":{\"type\":\"And\",\"value\":[]}} "
  -- Slate of Ancestry's "Discard your hand".
  Spec.it s "MkDiscardCards, every card in hand" $
    Common.assertCodec
      s
      codec
      ( DiscardCards.MkDiscardCards
          { DiscardCards.count = CardCount.Every,
            DiscardCards.whichCards = Filter.And []
          }
      )
      " {\"count\":{\"type\":\"Every\"},\"whichCards\":{\"type\":\"And\",\"value\":[]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
