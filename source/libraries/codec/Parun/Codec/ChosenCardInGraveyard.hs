{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ChosenCardInGraveyard where

import qualified Parun.Codec.Chooser as Chooser
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.Codec.ZoneScope as ZoneScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ChosenCardInGraveyard as ChosenCardInGraveyard
import qualified Parun.Types.Quantity as Quantity

-- | A bare object keyed by the record's field names, replacing the three-element
-- array this payload used to be (#1464).
--
-- @count@ is defaulted rather than required, so the printed singular -- every
-- card in the pool but Fall of the Thran -- writes no key.
codec :: Codec.Codec ChosenCardInGraveyard.ChosenCardInGraveyard
codec = Fields.object $ do
  chooser <- Fields.required "chooser" Chooser.codec ChosenCardInGraveyard.chooser
  players <- Fields.required "players" ZoneScope.codec ChosenCardInGraveyard.players
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) ChosenCardInGraveyard.filter
  count <- Fields.defaulted "count" (Quantity.Literal 1) Quantity.codec ChosenCardInGraveyard.count
  pure
    ChosenCardInGraveyard.MkChosenCardInGraveyard
      { ChosenCardInGraveyard.chooser = chooser,
        ChosenCardInGraveyard.players = players,
        ChosenCardInGraveyard.filter = filter_,
        ChosenCardInGraveyard.count = count
      }
