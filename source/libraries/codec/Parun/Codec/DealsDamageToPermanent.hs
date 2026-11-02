{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DealsDamageToPermanent where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.CardType as CardType
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DealsDamageToPermanent as DealsDamageToPermanent

-- | A bare object keyed by the record's field names, as
-- Parun.Codec.DealsDamageToPlayer is. `kind` is optional, for damage of any kind.
codec :: Codec.Codec DealsDamageToPermanent.DealsDamageToPermanent
codec = Fields.object $ do
  actor <- Fields.required "actor" ActingPermanent.codec DealsDamageToPermanent.actor
  recipient <- Fields.required "recipient" CardType.codec DealsDamageToPermanent.recipient
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) DealsDamageToPermanent.kind
  pure DealsDamageToPermanent.MkDealsDamageToPermanent {DealsDamageToPermanent.actor = actor, DealsDamageToPermanent.recipient = recipient, DealsDamageToPermanent.kind = kind}
