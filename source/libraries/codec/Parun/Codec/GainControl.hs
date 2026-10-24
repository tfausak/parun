{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.GainControl where

import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.ObjectRef as ObjectRef
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | A bare object keyed by the record's field names. `to` elided is "you", the
-- effect's controller (CR 109.5).
codec :: Codec.Codec GainControl.GainControl
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec GainControl.duration
  ref <- Fields.required "ref" ObjectRef.codec GainControl.ref
  to <- Fields.defaulted "to" (PlayerRef.Relative PlayerRelation.You) PlayerRef.codec GainControl.to
  pure
    GainControl.MkGainControl
      { GainControl.duration = duration,
        GainControl.ref = ref,
        GainControl.to = to
      }
