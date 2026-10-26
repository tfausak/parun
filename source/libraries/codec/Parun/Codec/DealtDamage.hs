{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DealtDamage where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealtDamage as DealtDamage

-- | A bare object keyed by the record's field names, the player written with
-- whichever codec its parameter takes. `kind` is 'Fields.defaulted', so a card
-- watching any damage writes only `player`.
codec :: (Typeable.Typeable player) => Codec.Codec player -> Codec.Codec (DealtDamage.DealtDamage player)
codec playerCodec = Fields.object $ do
  player <- Fields.required "player" playerCodec DealtDamage.player
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) DealtDamage.kind
  pure DealtDamage.MkDealtDamage {DealtDamage.player = player, DealtDamage.kind = kind}
