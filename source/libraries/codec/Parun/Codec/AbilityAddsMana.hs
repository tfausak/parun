{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AbilityAddsMana where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ManaSpecification as ManaSpecification
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AbilityAddsMana as AbilityAddsMana

-- | A bare object keyed by the record's field names, every key required for
-- Parun.Codec.PermanentTappedForMana's reason.
codec :: Codec.Codec AbilityAddsMana.AbilityAddsMana
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec AbilityAddsMana.player
  source <- Fields.required "source" (Filter.codec Keyword.codec) AbilityAddsMana.source
  mana <- Fields.required "mana" ManaSpecification.codec AbilityAddsMana.mana
  pure AbilityAddsMana.MkAbilityAddsMana {AbilityAddsMana.player = player, AbilityAddsMana.source = source, AbilityAddsMana.mana = mana}
