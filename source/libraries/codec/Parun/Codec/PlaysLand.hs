{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlaysLand where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlaysLand as PlaysLand

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayerActsOn is. "from" defaults to any zone, as
-- Parun.Codec.SpellCast's "zone" does; the unrestricted land spells itself out
-- as the trivial Filter.
codec :: Codec.Codec PlaysLand.PlaysLand
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec PlaysLand.player
  from <- Fields.defaulted "from" Nothing (Common.maybe Zone.codec) PlaysLand.from
  filter_ <- Fields.required "filter" (Filter.codec Keyword.codec) PlaysLand.filter
  pure PlaysLand.MkPlaysLand {PlaysLand.player = player, PlaysLand.from = from, PlaysLand.filter = filter_}
