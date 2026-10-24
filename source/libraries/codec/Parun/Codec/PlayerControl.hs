{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerControl where

import qualified Parun.Codec.ControlDuration as ControlDuration
import qualified Parun.Codec.Decider as Decider
import qualified Parun.Codec.Timestamp as Timestamp
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerControl as PlayerControl

-- | An object keyed by the record's field names, with rule 723.7's restriction
-- elided when it is absent -- which is every rule 723.1 control.
codec :: Codec.Codec PlayerControl.PlayerControl
codec = Fields.object $ do
  decider <- Fields.required "decider" Decider.codec PlayerControl.decider
  duration <- Fields.required "duration" ControlDuration.codec PlayerControl.duration
  manaFromLandsOnly <- Fields.defaulted "manaFromLandsOnly" False Common.boolean PlayerControl.manaFromLandsOnly
  timestamp <- Fields.required "timestamp" Timestamp.codec PlayerControl.timestamp
  pure
    PlayerControl.MkPlayerControl
      { PlayerControl.decider = decider,
        PlayerControl.duration = duration,
        PlayerControl.manaFromLandsOnly = manaFromLandsOnly,
        PlayerControl.timestamp = timestamp
      }
