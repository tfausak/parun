{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExileCardsFromHand where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CostAmount as CostAmount
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExileCardsFromHand as ExileCardsFromHand

-- | A bare object keyed by the record's field names. The keyword codec is a
-- PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (ExileCardsFromHand.ExileCardsFromHand keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" CostAmount.codec ExileCardsFromHand.count
  whichCards <- Fields.required "whichCards" (Filter.codec keywordCodec) ExileCardsFromHand.whichCards
  pure ExileCardsFromHand.MkExileCardsFromHand {ExileCardsFromHand.count = count, ExileCardsFromHand.whichCards = whichCards}
