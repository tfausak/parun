{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DamageEvent where

import qualified Data.Set as Set
import qualified Parun.Codec.DamageKind as DamageKind
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Recipient as Recipient
import qualified Parun.Codec.Subtype as Subtype
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DamageEvent as DamageEvent

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: Codec.Codec DamageEvent.DamageEvent
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec DamageEvent.source
  target <- Fields.required "target" Recipient.codec DamageEvent.target
  amount <- Fields.required "amount" Common.natural DamageEvent.amount
  dealtByDeathtouch <- Fields.defaulted "dealtByDeathtouch" False Common.boolean DamageEvent.dealtByDeathtouch
  dealtByInfect <- Fields.defaulted "dealtByInfect" False Common.boolean DamageEvent.dealtByInfect
  dealtByWither <- Fields.defaulted "dealtByWither" False Common.boolean DamageEvent.dealtByWither
  dealtByToxic <- Fields.defaulted "dealtByToxic" 0 Common.natural DamageEvent.dealtByToxic
  -- CR 702.15b's answer is a player or nobody, so Nothing (no lifelink at deal
  -- time) is what an absent key means.
  dealtByLifelink <- Fields.defaulted "dealtByLifelink" Nothing (Common.maybe PlayerId.codec) DamageEvent.dealtByLifelink
  -- CR 702.76a and CR 702.173a: three deal-time reads about the SOURCE, each
  -- defaulted to the answer an absent key gives -- nobody controlled it, it had
  -- no creature types, it was no commander.
  dealtByController <- Fields.defaulted "dealtByController" Nothing (Common.maybe PlayerId.codec) DamageEvent.dealtByController
  dealtByCreatureTypes <- Fields.defaulted "dealtByCreatureTypes" Set.empty (Common.set Subtype.codec) DamageEvent.dealtByCreatureTypes
  dealtByCommander <- Fields.defaulted "dealtByCommander" False Common.boolean DamageEvent.dealtByCommander
  kind <- Fields.required "kind" DamageKind.codec DamageEvent.kind
  pure
    DamageEvent.MkDamageEvent
      { DamageEvent.source = source,
        DamageEvent.target = target,
        DamageEvent.amount = amount,
        DamageEvent.dealtByDeathtouch = dealtByDeathtouch,
        DamageEvent.dealtByInfect = dealtByInfect,
        DamageEvent.dealtByWither = dealtByWither,
        DamageEvent.dealtByToxic = dealtByToxic,
        DamageEvent.dealtByLifelink = dealtByLifelink,
        DamageEvent.dealtByController = dealtByController,
        DamageEvent.dealtByCreatureTypes = dealtByCreatureTypes,
        DamageEvent.dealtByCommander = dealtByCommander,
        DamageEvent.kind = kind
      }
