{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Shows where

import qualified Parun.Codec.Audience as Audience
import qualified Parun.Codec.ShownCards as ShownCards
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Shows as Shows

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec Shows.Shows
codec = Fields.object $ do
  cards <- Fields.required "cards" ShownCards.codec Shows.cards
  to <- Fields.required "to" Audience.codec Shows.to
  pure Shows.MkShows {Shows.cards = cards, Shows.to = to}
