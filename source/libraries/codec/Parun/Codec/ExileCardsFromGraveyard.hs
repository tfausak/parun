{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ExileCardsFromGraveyard where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Filter as Filter
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ExileCardsFromGraveyard as ExileCardsFromGraveyard

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464). The keyword codec is a PARAMETER; see
-- Parun.Codec.Filter's header.
codec :: (Typeable.Typeable keyword, Eq keyword) => Codec.Codec keyword -> Codec.Codec (ExileCardsFromGraveyard.ExileCardsFromGraveyard keyword)
codec keywordCodec = Fields.object $ do
  count <- Fields.required "count" Common.natural ExileCardsFromGraveyard.count
  whichCards <- Fields.required "whichCards" (Filter.codec keywordCodec) ExileCardsFromGraveyard.whichCards
  pure ExileCardsFromGraveyard.MkExileCardsFromGraveyard {ExileCardsFromGraveyard.count = count, ExileCardsFromGraveyard.whichCards = whichCards}
