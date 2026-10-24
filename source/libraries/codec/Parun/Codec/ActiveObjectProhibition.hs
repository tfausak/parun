{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveObjectProhibition where

import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Prohibition as Prohibition
import qualified Parun.Codec.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveObjectProhibition as ActiveObjectProhibition

codec :: Codec.Codec ActiveObjectProhibition.ActiveObjectProhibition
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveObjectProhibition.source
  controller <- Fields.required "controller" PlayerId.codec ActiveObjectProhibition.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveObjectProhibition.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveObjectProhibition.expiry
  what <- Fields.required "what" Prohibition.codec ActiveObjectProhibition.what
  affected <- Fields.required "affected" (RestrictedCreatures.codec ObjectId.codec) ActiveObjectProhibition.affected
  pure
    ActiveObjectProhibition.MkActiveObjectProhibition
      { ActiveObjectProhibition.source = source,
        ActiveObjectProhibition.controller = controller,
        ActiveObjectProhibition.timestamp = timestamp,
        ActiveObjectProhibition.expiry = expiry,
        ActiveObjectProhibition.what = what,
        ActiveObjectProhibition.affected = affected
      }
