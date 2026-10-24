{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PermanentTappedForMana where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaSpecification as ManaSpecification
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PermanentTappedForMana as PermanentTappedForMana

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PermanentSacrificed is, and every key required for that codec's
-- reason: no part of the printed sentence has a default.
codec :: Codec.Codec PermanentTappedForMana.PermanentTappedForMana
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec PermanentTappedForMana.player
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PermanentTappedForMana.filter
  mana <- Fields.required "mana" ManaSpecification.codec PermanentTappedForMana.mana
  pure PermanentTappedForMana.MkPermanentTappedForMana {PermanentTappedForMana.player = player, PermanentTappedForMana.filter = filter_, PermanentTappedForMana.mana = mana}
