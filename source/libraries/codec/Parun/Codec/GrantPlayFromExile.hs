{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.GrantPlayFromExile where

import qualified Parun.Codec.Condition as Condition
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ManaSpending as ManaSpending
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PermissionCost as PermissionCost
import qualified Parun.Codec.PermissionVerb as PermissionVerb
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.TapState as TapState
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.GrantPlayFromExile as GrantPlayFromExile
import qualified Parun.Types.ManaSpending as ManaSpending
import qualified Parun.Types.PermissionVerb as PermissionVerb.Type
import qualified Parun.Types.PlayerRef as PlayerRef.Type
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TapState as TapState.Type
import qualified Parun.Types.Zone as Zone.Type

-- | A bare object keyed by the record's field names, with each rider elided when
-- it is the default -- Parun.Codec.OfferCast's posture with its CastOffer, and
-- for the same reason: a permission that says nothing about mana is the ordinary
-- one, so a key belongs only on the card that prints CR 118.14's clause or CR
-- 118.9's. `player` defaults for that reason too: CR 109.5's "you" is what a
-- permission naming no seat means, and Parun.Codec.OfferCast's `caster` takes the
-- same default.
codec :: Codec.Codec GrantPlayFromExile.GrantPlayFromExile
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec GrantPlayFromExile.duration
  player <- Fields.defaulted "player" (PlayerRef.Type.Relative PlayerRelation.You) PlayerRef.codec GrantPlayFromExile.player
  ref <- Fields.required "ref" ObjectRef.codec GrantPlayFromExile.ref
  spending <- Fields.defaulted "spending" ManaSpending.AsProduced ManaSpending.codec GrantPlayFromExile.spending
  alternativeCost <- Fields.defaulted "alternativeCost" Nothing (Common.maybe PermissionCost.codec) GrantPlayFromExile.alternativeCost
  condition <- Fields.defaulted "condition" Nothing (Common.maybe Condition.codec) GrantPlayFromExile.condition
  verb <- Fields.defaulted "verb" PermissionVerb.Type.Play PermissionVerb.codec GrantPlayFromExile.verb
  increase <- Fields.defaulted "increase" 0 Common.natural GrantPlayFromExile.increase
  landEnters <- Fields.defaulted "landEnters" TapState.Type.Untapped TapState.codec GrantPlayFromExile.landEnters
  upTo <- Fields.defaulted "upTo" Nothing (Common.maybe Common.natural) GrantPlayFromExile.upTo
  zone <- Fields.defaulted "zone" Zone.Type.Exile Zone.codec GrantPlayFromExile.zone
  pure
    GrantPlayFromExile.MkGrantPlayFromExile
      { GrantPlayFromExile.duration = duration,
        GrantPlayFromExile.player = player,
        GrantPlayFromExile.ref = ref,
        GrantPlayFromExile.spending = spending,
        GrantPlayFromExile.alternativeCost = alternativeCost,
        GrantPlayFromExile.condition = condition,
        GrantPlayFromExile.verb = verb,
        GrantPlayFromExile.increase = increase,
        GrantPlayFromExile.landEnters = landEnters,
        GrantPlayFromExile.upTo = upTo,
        GrantPlayFromExile.zone = zone
      }
