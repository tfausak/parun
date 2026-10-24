module Parun.Codec.AffectedPlayers where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PlayerScope as PlayerScope
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.AffectedPlayers as AffectedPlayers

-- | Tagged, in Parun.Codec.ZoneScope's shape for the same pair of readings: a
-- nested PlayerScope, or the thing the second arm names.
--
-- PARAMETRIC in that second thing, because both of the type's instantiations are
-- now serialized: a CARD writes @AffectedPlayers SlotName@ (Parun.Codec.AffectPlayers
-- passes Parun.Codec.SlotName's codec) and the store holds @AffectedPlayers PlayerId@
-- on Parun.Types.ActivePlayerEffect (Parun.Codec.ActivePlayerEffect passes
-- Parun.Codec.PlayerId's). Neither instantiation gains an arm it cannot answer,
-- so no lint is owed to keep a card from writing a seat.
codec ::
  (Typeable.Typeable player) =>
  Codec.Codec player ->
  Codec.Codec (AffectedPlayers.AffectedPlayers player)
codec playerCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "Scoped" PlayerScope.codec AffectedPlayers.Scoped (\x -> case x of AffectedPlayers.Scoped y -> Just y; _ -> Nothing),
      Arm.payload "Named" playerCodec AffectedPlayers.Named (\x -> case x of AffectedPlayers.Named y -> Just y; _ -> Nothing)
    ]

tagOf :: AffectedPlayers.AffectedPlayers player -> String
tagOf x = case x of
  AffectedPlayers.Scoped {} -> "Scoped"
  AffectedPlayers.Named {} -> "Named"
