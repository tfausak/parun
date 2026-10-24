{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.InZone where

import qualified Data.Text as Text
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Zone as Zone
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Zone as Zone

-- | The invariant Parun.Types.InZone states, enforced HERE, this being where a
-- scope enters the engine at all: a shared zone is undivided, so "one player's
-- share of the battlefield" names nothing, and the reference beside such a zone
-- can only be the whole table. It reads both fields, which is what
-- 'Fields.objectWith' is for.
--
-- The question a card means when it writes one is CONTROL or OWNERSHIP of the
-- objects in the zone rather than a share of the zone itself -- Nightmare's
-- "Swamps you control" is @PlayerRef.Relative AnyPlayer@ with a
-- @Filter.ControlledBy You@ conjunct -- and both have their own spelling in the
-- Filter, which is where CR 110.2 and CR 108.3 can come apart. Without this the
-- pairing decoded and Parun.Engine.Count answered it off Game.zoneMembers, which
-- slices the shared battlefield by OWNER: a number, silently, for a question the
-- rules do not have (#161).
undividedShared :: InZone.InZone -> Either Text.Text InZone.InZone
undividedShared inZone
  | Zone.shared (InZone.zone inZone) && InZone.player inZone /= PlayerRef.Relative PlayerRelation.AnyPlayer =
      Left (Text.pack ("InZone: CR 400.1 makes " <> show (InZone.zone inZone) <> " shared by all players, so it cannot be scoped to " <> show (InZone.player inZone)))
  | otherwise = Right inZone

-- | A bare object keyed by the record's field names, replacing the two-element
-- array this payload used to be (#1464).
codec :: Codec.Codec InZone.InZone
codec = Fields.objectWith undividedShared $ do
  zone <- Fields.required "zone" Zone.codec InZone.zone
  player <- Fields.required "player" PlayerRef.codec InZone.player
  pure InZone.MkInZone {InZone.zone = zone, InZone.player = player}
