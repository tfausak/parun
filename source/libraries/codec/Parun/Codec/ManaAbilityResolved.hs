{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ManaAbilityResolved where

import qualified Parun.Codec.ObjectId as ObjectId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ManaAbilityResolved as ManaAbilityResolved

-- | A bare object keyed by the record's field names, both keys required for
-- Parun.Codec.ManaAdded's reason: a log entry whose one producer
-- (Parun.Engine.Cost.tapForManaWith) always knows both.
codec :: Codec.Codec ManaAbilityResolved.ManaAbilityResolved
codec = Fields.object $ do
  permanent <- Fields.required "permanent" ObjectId.codec ManaAbilityResolved.permanent
  amount <- Fields.required "amount" Common.natural ManaAbilityResolved.amount
  pure ManaAbilityResolved.MkManaAbilityResolved {ManaAbilityResolved.permanent = permanent, ManaAbilityResolved.amount = amount}
