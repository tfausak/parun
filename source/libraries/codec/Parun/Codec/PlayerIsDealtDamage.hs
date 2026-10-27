{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerIsDealtDamage where

import qualified Parun.Codec.DealtDamage as DealtDamage
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage

-- | A bare object keyed by the record's field names. `orTheirPlaneswalkers`
-- defaults to False, so a card watching the player alone writes only `dealt`.
codec :: Codec.Codec PlayerIsDealtDamage.PlayerIsDealtDamage
codec = Fields.object $ do
  dealt <- Fields.required "dealt" (DealtDamage.codec PlayerRelation.codec) PlayerIsDealtDamage.dealt
  orTheirPlaneswalkers <- Fields.defaulted "orTheirPlaneswalkers" False Common.boolean PlayerIsDealtDamage.orTheirPlaneswalkers
  pure PlayerIsDealtDamage.MkPlayerIsDealtDamage {PlayerIsDealtDamage.dealt = dealt, PlayerIsDealtDamage.orTheirPlaneswalkers = orTheirPlaneswalkers}
