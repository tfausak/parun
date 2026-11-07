{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerIsDealtDamage where

import qualified Parun.Codec.Batching as Batching
import qualified Parun.Codec.DealtDamage as DealtDamage
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.Codec.TurnScope as TurnScope
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealtDamage as DealtDamageType
import qualified Parun.Types.PlayerIsDealtDamage as PlayerIsDealtDamage
import qualified Parun.Types.PlayerRelation as PlayerRelationType

-- | A bare object keyed by the record's field names. `dealt` is required; every
-- other field defaults to PlayerIsDealtDamage.watching's and writes no key.
codec :: Codec.Codec PlayerIsDealtDamage.PlayerIsDealtDamage
codec = Fields.object $ do
  dealt <- Fields.required "dealt" (DealtDamage.codec PlayerRelation.codec) PlayerIsDealtDamage.dealt
  orTheirPlaneswalkers <- Fields.defaulted "orTheirPlaneswalkers" False Common.boolean PlayerIsDealtDamage.orTheirPlaneswalkers
  batching <- Fields.defaulted "batching" (PlayerIsDealtDamage.batching defaults) Batching.codec PlayerIsDealtDamage.batching
  scope <- Fields.defaulted "scope" (PlayerIsDealtDamage.scope defaults) TurnScope.codec PlayerIsDealtDamage.scope
  pure
    PlayerIsDealtDamage.MkPlayerIsDealtDamage
      { PlayerIsDealtDamage.dealt = dealt,
        PlayerIsDealtDamage.orTheirPlaneswalkers = orTheirPlaneswalkers,
        PlayerIsDealtDamage.batching = batching,
        PlayerIsDealtDamage.scope = scope
      }
  where
    -- `dealt` is required, so the one given here is never read.
    defaults = PlayerIsDealtDamage.watching (DealtDamageType.MkDealtDamage PlayerRelationType.You Nothing Nothing)
