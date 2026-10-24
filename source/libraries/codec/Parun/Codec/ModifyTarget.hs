{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.ModifyTarget where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.Modification as Modification
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ModifyTarget as ModifyTarget

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's ModifyTarget arm.
--
-- Takes the GRANTED ABILITY's codec, for Parun.Codec.Modification's reason:
-- naming Parun.Codec.GrantedAbility here would close the module cycle the type's
-- own parameter opens.
codec :: (Typeable.Typeable ability, Eq ability) => Codec.Codec ability -> Codec.Codec (ModifyTarget.ModifyTarget ability)
codec abilityCodec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec ModifyTarget.duration
  modification <- Fields.required "modification" (Modification.codec abilityCodec) ModifyTarget.modification
  ref <- Fields.required "ref" ObjectRef.codec ModifyTarget.ref
  each <- Fields.defaulted "each" Nothing (Common.maybe SlotName.codec) ModifyTarget.each
  pure
    ModifyTarget.MkModifyTarget
      { ModifyTarget.duration = duration,
        ModifyTarget.modification = modification,
        ModifyTarget.ref = ref,
        ModifyTarget.each = each
      }
