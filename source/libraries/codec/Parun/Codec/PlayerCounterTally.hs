{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerCounterTally where

import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerCounterTally as PlayerCounterTally

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464). The tag that picks it is
-- Parun.Codec.Quantity's "PlayerCounters", which this module is deliberately not
-- named after -- see Parun.Types.PlayerCounterTally.
codec :: Codec.Codec PlayerCounterTally.PlayerCounterTally
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec PlayerCounterTally.player
  kind <- Fields.required "kind" PlayerCounterKind.codec PlayerCounterTally.kind
  pure PlayerCounterTally.MkPlayerCounterTally {PlayerCounterTally.player = player, PlayerCounterTally.kind = kind}
