{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DiscardCards where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DiscardCards as DiscardCards

-- | A bare object keyed by the record's field names, Parun.Codec.ExileCardsFromGraveyard's
-- shape. The keyword codec is a PARAMETER; see Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (DiscardCards.DiscardCards keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural DiscardCards.count
  whichCards <- Fields.required "whichCards" (Filter.codec keywordCodec) DiscardCards.whichCards
  pure DiscardCards.MkDiscardCards {DiscardCards.count = count, DiscardCards.whichCards = whichCards}
