{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PlayerDesignationTally where

import qualified Parun.Codec.PlayerDesignation as PlayerDesignation
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.PlayerDesignationTally as PlayerDesignationTally

-- | A bare object keyed by the record's field names, Parun.Codec.PlayerCounterTally's
-- shape. The tag that picks it is Parun.Codec.Quantity's "HasPlayerDesignation".
codec :: Codec.Codec PlayerDesignationTally.PlayerDesignationTally
codec = Fields.object $ do
  player <- Fields.required "player" PlayerRef.codec PlayerDesignationTally.player
  designation <- Fields.required "designation" PlayerDesignation.codec PlayerDesignationTally.designation
  pure PlayerDesignationTally.MkPlayerDesignationTally {PlayerDesignationTally.player = player, PlayerDesignationTally.designation = designation}
