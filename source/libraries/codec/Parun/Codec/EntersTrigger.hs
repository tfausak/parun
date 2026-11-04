{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.EntersTrigger where

import qualified Parun.Codec.ActingPermanent as ActingPermanent
import qualified Parun.Codec.Batching as Batching
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.EntersTrigger as EntersTrigger

-- | A bare object keyed by the record's field names. The source and
-- EachOccurrence write no key (EntersTrigger.defaultValue).
codec :: Codec.Codec EntersTrigger.EntersTrigger
codec = Fields.object $ do
  permanent <- Fields.defaulted "permanent" (EntersTrigger.permanent EntersTrigger.defaultValue) ActingPermanent.codec EntersTrigger.permanent
  batching <- Fields.defaulted "batching" (EntersTrigger.batching EntersTrigger.defaultValue) Batching.codec EntersTrigger.batching
  pure
    EntersTrigger.MkEntersTrigger
      { EntersTrigger.permanent = permanent,
        EntersTrigger.batching = batching
      }
