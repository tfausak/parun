{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamageTrigger where

import qualified Data.Set as Set
import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.DamageRecipient as DamageRecipient
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageTrigger as DamageTrigger

-- | A bare object keyed by the record's field names. Any kind and any
-- recipient write no key.
codec :: Codec.Codec DamageTrigger.DamageTrigger
codec = Fields.object $ do
  actor <- Fields.required "actor" ActingPermanent.codec DamageTrigger.actor
  kind <- Fields.defaulted "kind" Nothing (Common.maybe DamageKind.codec) DamageTrigger.kind
  recipients <- Fields.defaulted "recipients" Set.empty (Common.set DamageRecipient.codec) DamageTrigger.recipients
  pure
    DamageTrigger.MkDamageTrigger
      { DamageTrigger.actor = actor,
        DamageTrigger.kind = kind,
        DamageTrigger.recipients = recipients
      }
