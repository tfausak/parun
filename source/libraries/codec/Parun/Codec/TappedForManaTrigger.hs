{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.TappedForManaTrigger where

import qualified Parun.Codec.ManaSpecification as ManaSpecification
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TappedPermanent as TappedPermanent
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.TappedForManaTrigger as TappedForManaTrigger

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerActsOn is, and every key required for that codec's
-- reason: no part of the printed sentence has a default.
codec :: Codec.Codec TappedForManaTrigger.TappedForManaTrigger
codec = Fields.object $ do
  permanent <- Fields.required "permanent" TappedPermanent.codec TappedForManaTrigger.permanent
  player <- Fields.required "player" PlayerRelation.codec TappedForManaTrigger.player
  mana <- Fields.required "mana" ManaSpecification.codec TappedForManaTrigger.mana
  pure TappedForManaTrigger.MkTappedForManaTrigger {TappedForManaTrigger.permanent = permanent, TappedForManaTrigger.player = player, TappedForManaTrigger.mana = mana}
