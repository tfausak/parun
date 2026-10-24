{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ActiveEvasion where

import qualified Parun.Codec.Expiry as Expiry
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ActiveEvasion as ActiveEvasion

codec :: Codec.Codec ActiveEvasion.ActiveEvasion
codec = Fields.object $ do
  source <- Fields.required "source" ObjectId.codec ActiveEvasion.source
  controller <- Fields.required "controller" PlayerId.codec ActiveEvasion.controller
  timestamp <- Fields.required "timestamp" Timestamp.codec ActiveEvasion.timestamp
  expiry <- Fields.required "expiry" Expiry.codec ActiveEvasion.expiry
  affected <- Fields.required "affected" (Filter.codec Keyword.codec) ActiveEvasion.affected
  blockers <- Fields.required "blockers" (Filter.codec Keyword.codec) ActiveEvasion.blockers
  pure
    ActiveEvasion.MkActiveEvasion
      { ActiveEvasion.source = source,
        ActiveEvasion.controller = controller,
        ActiveEvasion.timestamp = timestamp,
        ActiveEvasion.expiry = expiry,
        ActiveEvasion.affected = affected,
        ActiveEvasion.blockers = blockers
      }
