{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.ChosenCardInHand where

import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.Codec.Quantity as Quantity
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.ChosenCardInHand as ChosenCardInHand
import qualified Pawl.Types.Quantity as Quantity

-- | A bare object keyed by the record's field names, the shape every other
-- 'Pawl.Types.ObjectRef' payload record takes. @count@ is defaulted, so the
-- singular "a card from your hand" writes no key.
codec :: Codec.Codec ChosenCardInHand.ChosenCardInHand
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec ChosenCardInHand.player
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ChosenCardInHand.filter
  count <- Fields.defaulted "count" (Quantity.Literal 1) Quantity.codec ChosenCardInHand.count
  pure
    ChosenCardInHand.MkChosenCardInHand
      { ChosenCardInHand.player = player,
        ChosenCardInHand.filter = filter_,
        ChosenCardInHand.count = count
      }
