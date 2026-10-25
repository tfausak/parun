{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerIsDealtDamage where

import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.PlayersDealtDamage is. `kind` is 'Fields.defaulted', so a card
-- watching any damage writes only `player`.
codec :: Codec.Codec PlayerIsDealtDamage.PlayerIsDealtDamage
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRelation.codec PlayerIsDealtDamage.player
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) PlayerIsDealtDamage.kind
  pure PlayerIsDealtDamage.MkPlayerIsDealtDamage {PlayerIsDealtDamage.player = player, PlayerIsDealtDamage.kind = kind}
