{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.AffectPlayers where

import qualified Parun.Codec.AffectedPlayers as AffectedPlayers
import qualified Parun.Codec.Duration as Duration
import qualified Parun.Codec.PlayerEffect as PlayerEffect
import qualified Parun.Codec.SlotName as SlotName
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.AffectPlayers as AffectPlayers

-- | A bare object keyed by the record's field names. The tag that picks it is
-- written by Parun.Codec.Effect's AffectPlayers arm.
codec :: Codec.Codec AffectPlayers.AffectPlayers
codec = Fields.object $ do
  duration <- Fields.required "duration" Duration.codec AffectPlayers.duration
  players <- Fields.required "players" (AffectedPlayers.codec SlotName.codec) AffectPlayers.players
  effect <- Fields.required "effect" PlayerEffect.codec AffectPlayers.effect
  pure
    AffectPlayers.MkAffectPlayers
      { AffectPlayers.duration = duration,
        AffectPlayers.players = players,
        AffectPlayers.effect = effect
      }
