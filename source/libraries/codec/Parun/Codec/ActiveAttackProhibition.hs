{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveAttackProhibition where

import qualified Parun.Codec.AimedAt as AimedAt
import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveAttackProhibition as ActiveAttackProhibition

codec :: Codec.Codec ActiveAttackProhibition.ActiveAttackProhibition
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveAttackProhibition.source
  controller <- Fields.required "controller" PlayerId.codec ActiveAttackProhibition.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveAttackProhibition.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveAttackProhibition.expiry
  affected <- Fields.required "affected" (RestrictedCreatures.codec ObjectId.codec) ActiveAttackProhibition.affected
  aimedAt <- Fields.defaulted "aimedAt" Nothing (Common.maybe AimedAt.codec) ActiveAttackProhibition.aimedAt
  pure
    ActiveAttackProhibition.MkActiveAttackProhibition
      { ActiveAttackProhibition.source = source,
        ActiveAttackProhibition.controller = controller,
        ActiveAttackProhibition.timestamp = timestamp,
        ActiveAttackProhibition.expiry = expiry,
        ActiveAttackProhibition.affected = affected,
        ActiveAttackProhibition.aimedAt = aimedAt
      }
