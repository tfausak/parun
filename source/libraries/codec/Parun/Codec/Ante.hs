{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Ante where

import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Ante as Ante

-- | A bare object keyed by the record's field names, the slot elided when
-- absent.
codec :: Codec.Codec Ante.Ante
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec Ante.player
  ref <- Fields.required "ref" ObjectRef.codec Ante.ref
  slot <- Fields.defaulted "slot" Nothing (Common.maybe SlotName.codec) Ante.slot
  pure
    Ante.MkAnte
      { Ante.player = player,
        Ante.ref = ref,
        Ante.slot = slot
      }
