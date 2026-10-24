{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DealtDamageTo where

import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.DamagedParty as DamagedParty
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealtDamageTo as DealtDamageTo

-- | A bare object keyed by the record's field names. `kind` is
-- 'Fields.defaulted', so a card asking about any damage writes only `party`.
codec :: Codec.Codec DealtDamageTo.DealtDamageTo
codec = Fields.object $ do
  party <- Fields.required "party" DamagedParty.codec DealtDamageTo.party
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) DealtDamageTo.kind
  pure DealtDamageTo.MkDealtDamageTo {DealtDamageTo.party = party, DealtDamageTo.kind = kind}
