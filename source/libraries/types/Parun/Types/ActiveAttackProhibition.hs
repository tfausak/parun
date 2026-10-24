module Parun.Types.ActiveAttackProhibition where

import qualified Parun.Types.AimedAt as AimedAt
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.Timestamp as Timestamp

-- | CR 508.1c / 611.1: a stored, resolution-generated ATTACKING RESTRICTION,
-- held in GameState.attackProhibitions. Netter en-Dal's "target creature
-- can't attack this turn" and Chronomantic Escape's "until your next turn,
-- creatures can't attack you" are the producers.
--
-- Read at Parun.Engine.CombatRestriction.attackProhibited, which unions a row
-- naming no 'aimedAt' into that module's `cantAttack` beside CR 701.35a's
-- detentions, and at Parun.Engine.CombatRestriction.cantAttackPlayer, which
-- unions an aimed row into the printed carrier's announcement rows -- so CR
-- 508.1c sees one answer on each axis and Parun.Engine.Combat never learns which
-- road a restriction took. CR 508.1d's maximization ranges over the candidate
-- list `cantAttack` has already narrowed, which is that rule's "without
-- disobeying any restrictions".
--
-- OUTSIDE the layer system, which is CR 613.11: a restriction on a declaration
-- modifies the rules rather than any object's characteristics, so no
-- Parun.Types.Modification arm could carry it and Parun.Engine.Projection never
-- sees one.
--
-- 'affected' holds ids where the printed carrier (Parun.Types.ForbidAttack) holds
-- an ObjectRef, for Parun.Types.ActiveObjectProhibition's reason: the ref is read
-- ONCE, as the ability resolves. Its Matching arm is CR 611.2c's carve-out and
-- stays a Filter, re-read at each declaration against the live board.
--
-- `controller` is STORED, Parun.Types.ActivePlayerEffect's reason: a sorcery is in
-- a graveyard by the time its restriction is read, with no controller to project,
-- and 'aimedAt' asks CR 109.5's "you" of it at every declaration.
--
-- `expiry` decides when a Parun.Engine.Expiry sweep drops it (CR 514.2, 611.2a,
-- 611.2b); "this turn" arms Expiry.AtCleanup, "until your next turn" arms
-- Expiry.AtTurnOf and "during its controller's next turn" (Wall of Dust) arms
-- Expiry.DuringTurnOf.
--
-- That last one is the only arm a sweep does not settle on its own: its window
-- BEGINS on a later turn, so both readers above go through
-- Parun.Engine.CombatRestriction.liveAttackProhibitions, which drops a row whose
-- turn has not come. Parun.Types.Expiry names the carriers that ask.
--
-- `timestamp` is stored for ActiveObjectProhibition's reason: CR 613.11 orders by
-- CR 613.7 timestamp, and nothing observes this one because two prohibitions
-- cannot conflict -- CR 508.1c has no degrees.
--
-- No CR 508.1c "unless" gate, because Parun.Types.ForbidAttack states none for it
-- to carry.
--
-- Runtime-only: card data writes the printed carrier, never one of these. It
-- does have a codec (Parun.Codec.ActiveAttackProhibition), because a game in
-- progress has to be writable to JSON (#126).
data ActiveAttackProhibition = MkActiveAttackProhibition
  { source :: ObjectId.ObjectId,
    controller :: PlayerId.PlayerId,
    timestamp :: Timestamp.Timestamp,
    expiry :: Expiry.Expiry,
    affected :: RestrictedCreatures.RestrictedCreatures ObjectId.ObjectId,
    -- | Nothing is a restriction on attacking at all.
    aimedAt :: Maybe AimedAt.AimedAt
  }
  deriving (Eq, Ord, Show)
