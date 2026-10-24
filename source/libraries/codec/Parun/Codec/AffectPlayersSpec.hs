module Parun.Codec.AffectPlayersSpec where

import qualified Parun.Codec.AffectPlayers as AffectPlayers
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AffectPlayers as AffectPlayers
import qualified Parun.Types.AffectedPlayers as AffectedPlayers
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.PlayerEffect as PlayerEffect
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AffectPlayers" $ do
  -- A player effect installed over the players named, for a duration. The
  -- AffectedPlayers here is the SLOT instantiation, which is the only one with a
  -- codec: the PlayerId one is runtime-only and never reaches a card file.
  Spec.it s "MkAffectPlayers, all three keys" $
    Common.assertCodec
      s
      AffectPlayers.codec
      ( AffectPlayers.MkAffectPlayers
          { AffectPlayers.duration = Duration.UntilEndOfTurn,
            AffectPlayers.players = AffectedPlayers.Scoped (PlayerScope.Related PlayerRelation.Opponent),
            AffectPlayers.effect = PlayerEffect.CantCastSpells
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"players\":{\"type\":\"Scoped\",\"value\":{\"type\":\"Opponent\"}},\"effect\":{\"type\":\"CantCastSpells\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AffectPlayers.codec
