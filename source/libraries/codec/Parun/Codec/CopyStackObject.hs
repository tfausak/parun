{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.CopyStackObject where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.CopyException as CopyException
import qualified Parun.Codec.CopyTargets as CopyTargets
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CopyStackObject as CopyStackObject
import qualified Parun.Types.CopyTargets as CopyTargets

-- | CR 707.10's own answer is ELIDED when the card does not print another, the
-- way CreateCopy elides a count of one: a copy carries the original's targets
-- unless the effect says otherwise, so @Copied@ is what most of the shape would
-- repeat. A count of one is elided for the same reason, @copier@ for CR 707.10's
-- own "the player under whose control it was put on the stack", and @exceptions@
-- for Parun.Codec.BecomeCopy's: CR 707.9's "except ..." clause is absent from most
-- printings.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (CopyStackObject.CopyStackObject ability)
codec abilityCodec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec CopyStackObject.ref
  targets <- Fields.defaulted "targets" CopyTargets.defaultValue CopyTargets.codec CopyStackObject.targets
  quantity <- Fields.defaulted "quantity" CopyStackObject.defaultQuantity Quantity.codec CopyStackObject.quantity
  copier <- Fields.defaulted "copier" CopyStackObject.defaultCopier PlayerRef.codec CopyStackObject.copier
  exceptions <- Fields.defaulted "exceptions" [] (Common.list (CopyException.codec abilityCodec)) CopyStackObject.exceptions
  pure
    CopyStackObject.MkCopyStackObject
      { CopyStackObject.ref = ref,
        CopyStackObject.targets = targets,
        CopyStackObject.quantity = quantity,
        CopyStackObject.copier = copier,
        CopyStackObject.exceptions = exceptions
      }
