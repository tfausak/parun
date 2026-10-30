{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChosenCardInHand where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.HowMany as HowMany
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChosenCardInHand as ChosenCardInHand
import qualified Parun.Types.HowMany as HowMany

-- | A bare object keyed by the record's field names, the shape every other
-- 'Parun.Types.ObjectRef' payload record takes. @count@ is defaulted, so the
-- singular "a card from your hand" writes no key.
codec :: Codec.Codec ChosenCardInHand.ChosenCardInHand
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec ChosenCardInHand.player
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ChosenCardInHand.filter
  count <- Fields.defaulted "count" HowMany.one HowMany.codec ChosenCardInHand.count
  pure
    ChosenCardInHand.MkChosenCardInHand
      { ChosenCardInHand.player = player,
        ChosenCardInHand.filter = filter_,
        ChosenCardInHand.count = count
      }
