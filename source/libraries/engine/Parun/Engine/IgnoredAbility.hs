-- CR 116.2d: the SUPPRESSION side of the special action Parun.Engine.Ignore
-- offers and takes payment for. That module records a row on
-- GameState.ignoredAbilities; this one is the single question every carrier of
-- an ignorable ability asks about those rows, so a carrier cannot read them a
-- second way and drift.
--
-- Two questions, because CR 116.2d's "that player" reaches a carrier two ways. A
-- PLAYER-aimed ability suppresses for the player it names, which
-- Parun.Engine.PlayerEffect.applying has in hand. An OBJECT-aimed one names no
-- player at all, so the seat is derived from the restricted object: Volrath's
-- Curse offers the action to "that creature's controller", and it is that
-- player's payment that lets the creature attack, block and have its activated
-- abilities activated again.
--
-- Reads GameState.ignoredAbilities and nothing else about what was ignored:
-- neither the cost nor the grant is visible here, and no consumer learns which
-- card printed either.
module Parun.Engine.IgnoredAbility where

import qualified Parun.Engine.Projection.View as Projection
import qualified Parun.Types.AbilityName as AbilityName
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.IgnoredAbility as IgnoredAbility
import Parun.Types.ObjectId (ObjectId)
import Parun.Types.PlayerId (PlayerId)

-- CR 116.2d: has `pid` paid to ignore the ability `source` states under `name`?
--
-- The name is a Maybe because every carrier's is, and an UNNAMED row can never
-- be suppressed -- which is exact rather than a shortcut. Parun.AbilitySlotLintSpec
-- joins the two sides, so a face that names no ability grants no ignore either
-- and there is nothing that could have been paid for.
ignoredBy :: PlayerId -> ObjectId -> Maybe AbilityName.AbilityName -> GameState -> Bool
ignoredBy pid source name gs =
  let matches ignored =
        IgnoredAbility.player ignored == pid
          && IgnoredAbility.source ignored == source
          && Just (IgnoredAbility.ability ignored) == name
   in any matches (GameState.ignoredAbilities gs)

-- The same question about an OBJECT-aimed row, whose seat is CR 116.2d's "that
-- creature's controller" -- the one Volrath's Curse offers the action to, read
-- LIVE off the projection rather than off the row, so a creature that changed
-- hands since the payment answers for whoever controls it now.
--
-- A subject whose controller cannot be found suppresses nothing, which is the
-- honest answer: an object off the battlefield has no seat to have paid.
--
-- The EMPTY-LIST guard comes first, and it is what keeps this affordable: every
-- caller asks per (row, restricted object), and every board on which nobody has
-- taken the action would otherwise pay a control projection per pair.
ignoredForSubject :: ObjectId -> ObjectId -> Maybe AbilityName.AbilityName -> GameState -> Bool
ignoredForSubject subject source name gs
  | null (GameState.ignoredAbilities gs) = False
  | otherwise = case Projection.controllerOf subject gs of
      Nothing -> False
      Just pid -> ignoredBy pid source name gs
