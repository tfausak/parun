module Parun.Codec.ExileCardsFromHandSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ExileCardsFromHand as ExileCardsFromHand
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.CostAmount as CostAmount
import qualified Parun.Types.ExileCardsFromHand as ExileCardsFromHand
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (ExileCardsFromHand.ExileCardsFromHand Keyword.Keyword)
codec = ExileCardsFromHand.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ExileCardsFromHand" $ do
  -- CR 406.2 as a cost: Cadaverous Bloom exiles one card from your hand.
  Spec.it s "Fixed" $
    Common.assertCodec
      s
      codec
      ( ExileCardsFromHand.MkExileCardsFromHand
          { ExileCardsFromHand.count = CostAmount.Fixed 1,
            ExileCardsFromHand.whichCards = Filter.And []
          }
      )
      " {\"count\":{\"type\":\"Fixed\",\"value\":1},\"whichCards\":{\"type\":\"And\",\"value\":[]}} "
  -- CR 601.2b: March of Wretched Sorrow's "any number of black cards".
  Spec.it s "Announced" $
    Common.assertCodec
      s
      codec
      ( ExileCardsFromHand.MkExileCardsFromHand
          { ExileCardsFromHand.count = CostAmount.Announced (SlotName.MkSlotName (Text.pack "exiled")),
            ExileCardsFromHand.whichCards = Filter.HasColor Color.Black
          }
      )
      " {\"count\":{\"type\":\"Announced\",\"value\":\"exiled\"},\"whichCards\":{\"type\":\"HasColor\",\"value\":{\"type\":\"Black\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
