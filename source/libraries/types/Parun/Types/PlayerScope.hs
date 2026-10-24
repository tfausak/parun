module Parun.Types.PlayerScope where

import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Superlative as Superlative
import qualified Parun.Types.TurnRole as TurnRole

-- | A SET of players, named relative to a perspective: the player-side analogue of
-- Parun.Types.Affected, and much smaller because CR 109.5 fixes what "you" means.
-- Membership is Parun.Engine.PlayerEffect.inScope and the set is the fold over it,
-- Parun.Engine.PlayerEffect.playersInScope -- one reading, two shapes.
--
-- The carriers below differ only in where the perspective comes from, and the
-- first two take CR 109.5's "you":
--
--   * Parun.Types.PlayerStaticAbility / ActivePlayerEffect -- which players a
--     Parun.Types.PlayerEffect applies to, against the effect's CONTROLLER.
--   * Parun.Types.ZoneScope.Scoped -- whose copy of a per-player zone a target
--     slot, a resolution-time sweep or a resolution-time choice reaches (CR
--     400.1), for the readings CR 109.5 answers. That type's OTHER arm names a
--     slot, which is why it is not Parun.Types.PlayerRef and why every one of
--     those carriers takes a ZoneScope rather than this type: the two
--     PlayerEffect carriers above have no slots for an InSlot arm to be resolved
--     against.
--   * Parun.Types.PlayerEffect.CantBeTargetedBy -- whose spells and abilities
--     cannot target the player the effect applies to (CR 702.18a's shroud, CR
--     702.11c's hexproof). Its perspective is that PROTECTED player, which is
--     not CR 109.5's "you": the two coincide only because both cards in the pool
--     say "You have ...".
--   * Parun.Types.ChoosePlayer -- which players a resolving "choose a player"
--     offers (Stadium Vendors), against the resolving controller; the one
--     carrier that is an offer rather than an axis of application.
--   * Parun.Types.PlayerEffect.CantSearchLibraries, Parun.Types.AimedPlayers and
--     Parun.Types.CantAttackPlayer carry it too, each against its own perspective.
--
-- The scope is always resolved DYNAMICALLY on both PlayerEffect carriers. CR
-- 611.2c freezes a stored effect's OBJECT set -- which is what every stored
-- ContinuousEffect does (Affected.TheseObjects) -- but its third sentence carves
-- out an effect that modifies the rules rather than any object, which is this
-- axis. So there is no stored-set analogue of TheseObjects here: this is the same
-- type on the printed and the stored carrier. Freeze it and Silence, which
-- resolves with no opponent spell on the stack, does literally nothing.
data PlayerScope
  = -- | The players in this relation to the perspective (CR 109.5, 102.3).
    Related PlayerRelation.PlayerRelation
  | -- | CR 110.1 / 122.1: the players leading or trailing the table on a measure.
    --
    -- PERSPECTIVE-FREE, like AnyPlayer: the sentence names no "you" for a
    -- carrier to supply, so Parun.Engine.PlayerEffect.playersInScope answers it
    -- with an absent perspective. Its membership is a fact about the BOARD
    -- rather than about the two players being compared, which is why inScope
    -- takes a GameState at all.
    Superlative Superlative.Superlative
  | -- | CR 102.1 / 805.9: the players holding this role, read from the turn --
    -- the active players a "the active player" ability chooses one of (Siren's
    -- Call), or the defending players.
    InRole TurnRole.TurnRole
  | -- | CR 607.2d / 614.1c: the player the SOURCE chose as it entered -- Booby
    -- Trap's "the chosen player reveals each card they draw". Nobody where the
    -- carrier has no source to read, or the source chose nobody.
    ChosenPlayer
  deriving (Eq, Ord, Show)
