{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BecomeCopy where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CopyException as CopyException
import qualified Parun.Codec.CopyOriginal as CopyOriginal
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BecomeCopy as BecomeCopy

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's BecomeCopy arm. @exceptions@ is defaulted for
-- Parun.Codec.AsCopy's reason: CR 707.9's "except ..." clause is absent from most
-- printings, @newTargets@ for the same reason, and @duration@ is optional for the same reason -- most copy effects
-- state none.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (BecomeCopy.BecomeCopy ability)
codec abilityCodec = Fields.object $ do
  original <- Fields.required "original" CopyOriginal.codec BecomeCopy.original
  subject <- Fields.required "subject" ObjectRef.codec BecomeCopy.subject
  duration <- Fields.defaulted "duration" Nothing (Common.maybe Duration.codec) BecomeCopy.duration
  exceptions <- Fields.defaulted "exceptions" [] (Common.list (CopyException.codec abilityCodec)) BecomeCopy.exceptions
  newTargets <- Fields.defaulted "newTargets" False Common.boolean BecomeCopy.newTargets
  pure
    BecomeCopy.MkBecomeCopy
      { BecomeCopy.original = original,
        BecomeCopy.subject = subject,
        BecomeCopy.duration = duration,
        BecomeCopy.exceptions = exceptions,
        BecomeCopy.newTargets = newTargets
      }
