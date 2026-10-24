{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CardIdentity where

import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CardIdentity as CardIdentity

-- | A bare object keyed by the record's field names.
codec :: Codec.Codec CardIdentity.CardIdentity
codec = Fields.object $ do
  serial <- Fields.required "serial" Common.natural CardIdentity.serial
  startingOwner <- Fields.required "startingOwner" PlayerId.codec CardIdentity.startingOwner
  pure
    CardIdentity.MkCardIdentity
      { CardIdentity.serial = serial,
        CardIdentity.startingOwner = startingOwner
      }
