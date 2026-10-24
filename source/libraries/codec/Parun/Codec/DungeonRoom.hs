{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DungeonRoom where

import qualified Data.Set as Set
import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AbilityName as AbilityName
import qualified Parun.Codec.GrantedAbility as GrantedAbility
import qualified Parun.Codec.Modal as Modal
import qualified Parun.Codec.RoomIndex as RoomIndex
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DungeonRoom as DungeonRoom
import qualified Parun.Types.Face as Face

-- | The wire format is unchanged by the conversion to a bundle; what it adds is
-- the schema.
codec :: (Typeable.Typeable card, Eq card) => Codec.Codec card -> Codec.Codec (DungeonRoom.DungeonRoom card)
codec cardCodec = Fields.object $ do
  name <- Fields.required "name" AbilityName.codec DungeonRoom.name
  -- CR 309.4c: a room whose printed effect parun cannot express writes no
  -- ability, and the default is Face.defaultSpell -- one empty mode, the same
  -- value a vanilla creature's spell takes. No room in data/cards writes it
  -- today; every transcribed dungeon states all of its rooms' effects.
  ability <- Fields.defaulted "ability" Face.defaultSpell (Modal.codec cardCodec (GrantedAbility.codec cardCodec)) DungeonRoom.ability
  -- CR 309.4: the bottommost room has no arrows out of it, so an empty set is
  -- the common case and writes no key.
  exits <- Fields.defaulted "exits" Set.empty (Common.set RoomIndex.codec) DungeonRoom.exits
  pure
    DungeonRoom.MkDungeonRoom
      { DungeonRoom.name = name,
        DungeonRoom.ability = ability,
        DungeonRoom.exits = exits
      }
