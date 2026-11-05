{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CounteringTrigger where

import qualified Parun.Codec.CounteredKind as CounteredKind
import qualified Parun.Codec.PlayerRelation as PlayerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CounteringTrigger as CounteringTrigger

-- | A bare object keyed by the record's field names. A spell and any player
-- write no key (CounteringTrigger.defaultValue).
codec :: Codec.Codec CounteringTrigger.CounteringTrigger
codec = Fields.object $ do
  countered <- Fields.defaulted "countered" (CounteringTrigger.countered CounteringTrigger.defaultValue) CounteredKind.codec CounteringTrigger.countered
  counterer <- Fields.defaulted "counterer" (CounteringTrigger.counterer CounteringTrigger.defaultValue) PlayerRelation.codec CounteringTrigger.counterer
  pure
    CounteringTrigger.MkCounteringTrigger
      { CounteringTrigger.countered = countered,
        CounteringTrigger.counterer = counterer
      }
