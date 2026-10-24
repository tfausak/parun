{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayersDealtDamage where

import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayersDealtDamage as PlayersDealtDamage

-- | A bare object keyed by the record's field names. `kind` is
-- 'Fields.defaulted', so a card counting any damage writes only `player`.
codec :: Codec.Codec PlayersDealtDamage.PlayersDealtDamage
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec PlayersDealtDamage.player
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) PlayersDealtDamage.kind
  pure PlayersDealtDamage.MkPlayersDealtDamage {PlayersDealtDamage.player = player, PlayersDealtDamage.kind = kind}
