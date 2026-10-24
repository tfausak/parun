{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Destroy where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.Regenerability as Regenerability
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Destroy as Destroy

-- | Each of the three bound slots is ELIDED when absent, so a card that says
-- nothing about counting its sweep writes only the two keys it always did. That
-- elision was previously a third array element recovered by JSON TYPE; as a
-- named key it is just an absent key, and nothing has to be told apart (#1305).
codec :: Codec.Codec Destroy.Destroy
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec Destroy.ref
  regenerability <- Fields.required "regenerability" Regenerability.codec Destroy.regenerability
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Destroy.slot
  buried <- Fields.defaulted "buried" Nothing (Common.maybe SlotName.codec) Destroy.buried
  permanents <- Fields.defaulted "permanents" Nothing (Common.maybe SlotName.codec) Destroy.permanents
  pure
    Destroy.MkDestroy
      { Destroy.ref = ref,
        Destroy.regenerability = regenerability,
        Destroy.slot = slot,
        Destroy.buried = buried,
        Destroy.permanents = permanents
      }
