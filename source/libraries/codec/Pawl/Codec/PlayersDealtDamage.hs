{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.PlayersDealtDamage where

import qualified Pawl.Codec.DamageKind as DamageKind
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.PlayersDealtDamage as PlayersDealtDamage

-- | A bare object keyed by the record's field names. `kind` is
-- 'Fields.defaulted', so a card counting any damage writes only `player`.
codec :: Codec.Codec PlayersDealtDamage.PlayersDealtDamage
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec PlayersDealtDamage.player
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) PlayersDealtDamage.kind
  pure PlayersDealtDamage.MkPlayersDealtDamage {PlayersDealtDamage.player = player, PlayersDealtDamage.kind = kind}
