module Parun.Codec.DiscardCardsSpec where

import qualified Parun.Codec.DiscardCards as DiscardCards
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.DiscardCards as DiscardCards
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectCount as ObjectCount

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
          { DiscardCards.count = ObjectCount.Exactly (CostAmount.Fixed 1),
            DiscardCards.whichCards = Filter.HasCardType CardType.Land
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":1},\"whichCards\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}} "
  -- Cathartic Reunion's "discard two cards", which names none.
  Spec.it s "MkDiscardCards, a filter that admits everything" $
    Common.assertCodec
      s
      codec
      ( DiscardCards.MkDiscardCards
          { DiscardCards.count = ObjectCount.Exactly (CostAmount.Fixed 2),
            DiscardCards.whichCards = Filter.And []
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":2},\"whichCards\":{\"type\":\"And\",\"value\":[]}} "
  -- Slate of Ancestry's "Discard your hand".
  Spec.it s "MkDiscardCards, every card in hand" $
    Common.assertCodec
      s
      codec
      ( DiscardCards.MkDiscardCards
          { DiscardCards.count = ObjectCount.Every,
            DiscardCards.whichCards = Filter.And []
          }
      )
      " {\"count\":{\"type\":\"Every\"},\"whichCards\":{\"type\":\"And\",\"value\":[]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
