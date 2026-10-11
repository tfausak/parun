{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.Shows where

import qualified Pawl.Codec.Audience as Audience
import qualified Pawl.Codec.ShownCards as ShownCards
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.Shows as Shows

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec Shows.Shows
codec = Fields.object $ do
  cards <- Fields.required "cards" ShownCards.codec Shows.cards
  to <- Fields.required "to" Audience.codec Shows.to
  pure Shows.MkShows {Shows.cards = cards, Shows.to = to}
