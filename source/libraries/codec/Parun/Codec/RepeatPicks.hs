{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RepeatPicks where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RepeatPicks as RepeatPicks

-- | An object keyed by the record's field names, each defaulting to empty.
codec :: Codec.Codec RepeatPicks.RepeatPicks
codec = Fields.object $ do
  picked <- Fields.defaulted "picked" Map.empty (Common.naturalMap PlayerId.codec (Common.set ObjectId.codec)) RepeatPicks.picked
  refused <- Fields.defaulted "refused" Map.empty (Common.naturalMap PlayerId.codec (Common.set ObjectId.codec)) RepeatPicks.refused
  pure RepeatPicks.MkRepeatPicks {RepeatPicks.picked = picked, RepeatPicks.refused = refused}
