{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Reveal where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Reveal as Reveal

-- | The ref is REQUIRED and the slot is not -- MoveToZone's spelling rather than
-- LookAt's, since a reveal that binds nothing still shows the cards (CR
-- 701.20a). Every printing in the pool but Wild Evocation omits the key.
codec :: Codec.Codec Reveal.Reveal
codec = Fields.object $ do
  ref <- Fields.required "ref" ObjectRef.codec Reveal.ref
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Reveal.slot
  pure
    Reveal.MkReveal
      { Reveal.ref = ref,
        Reveal.slot = slot
      }
