{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.LookAt where

import qualified Pawl.Codec.ObjectRef as ObjectRef
import qualified Pawl.Codec.PlayerRef as PlayerRef
import qualified Pawl.Codec.SlotName as SlotName
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.LookAt as LookAt
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation

-- | @ref@ and @slot@ are REQUIRED, unlike MoveToZone's optional slot: a look that
-- binds nothing moves nothing and records nothing, so the key a card could omit
-- is the one that makes the instruction do anything at all. @looker@ defaults to
-- "you", the reading of every printed "look at" that names nobody.
codec :: Codec.Codec LookAt.LookAt
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec LookAt.ref
  slot <- Fields.required "slot" SlotName.codec LookAt.slot
  looker <- Fields.defaulted "looker" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec LookAt.looker
  pure
    LookAt.MkLookAt
      { LookAt.ref = ref,
        LookAt.slot = slot,
        LookAt.looker = looker
      }
