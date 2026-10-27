module Parun.Types.Expiry where

import qualified Parun.Types.AfterObjectTurn as AfterObjectTurn
import qualified Parun.Types.AfterTurn as AfterTurn
import qualified Parun.Types.EventExpiry as EventExpiry
import qualified Parun.Types.PaidExpiry as PaidExpiry
import qualified Parun.Types.PhaseSelector as PhaseSelector
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SlotName as SlotName
import qualified Parun.Types.StepBegan as StepBegan
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.While as While

-- | CR 611.2: how long a STORED effect lasts, as the game remembers it. The
-- runtime counterpart of the printed Parun.Types.Duration: card data says "until
-- your next turn", the game remembers WHOSE. Never appears in card JSON -- only
-- Parun.Engine.Expiry.arm makes one -- but it does have a runtime codec, since
-- CR 603.7b lets a delayed ability state a duration that must survive the trip.
--
-- The split is what makes a card-only value in GameState unrepresentable: with
-- one type carrying both, a printed arm leaking into a stored effect would match
-- no sweep and last forever, silently. Only Parun.Engine.Expiry may case on this.
data Expiry
  = -- | CR 514.2: "all 'until end of turn' and 'this turn' effects end" during
    -- the cleanup step.
    AtCleanup
  | -- | CR 611.2a: "lasts until the end of the game". No sweep ends it.
    Never
  | -- | Alchemy's "perpetually", stored: Never's lifetime, plus the identity
    -- Parun.Engine.Event.perpetuate keys on to re-anchor across CR 400.7.
    Perpetual
  | -- | CR 611.2b: "for as long as ...". The PlayerId is CR 109.5's "you", baked
    -- in by Parun.Engine.Expiry.arm at the moment the effect is stored -- derived from
    -- the effect's controller, never chosen. The duration is ONE continuous
    -- period: once the condition stops holding the effect is DELETED, and a
    -- condition that becomes true again does not bring it back.
    --
    -- The CONDITION is baked at the same moment (Parun.Engine.Condition.bakeBound):
    -- a PlayerRef naming one of the resolution's slots becomes PlayerRef.Specific,
    -- or HolderOfObject for a slot holding an object, since
    -- the sweep that re-reads this has no resolution to read a slot off.
    While While.While
  | -- | CR 611.2a: "until your next turn", as a concrete player. Ends as that
    -- player's turn begins.
    AtTurnOf PlayerId.PlayerId
  | -- | CR 611.2a: Duration.UntilYourNextStep, as a concrete player.
    -- Ends as that step of that player's turn next begins, before anything
    -- triggered then is put on the stack (CR 117.3a).
    AtStepOf StepBegan.StepBegan
  | -- | CR 611.2a: "until the end of your next turn", as a concrete player and
    -- the turn the duration began on. Ends as that player's next turn ends, in
    -- its cleanup step (CR 514) -- a whole turn later than AtTurnOf above.
    --
    -- Carries the turn NUMBER as well as the player because the two readings
    -- differ only when the duration begins during that player's own turn: the
    -- sweep ends this at the first turn of theirs numbered above it, so their
    -- current turn is not mistaken for their next one.
    AtEndOfTurnOf AfterTurn.AfterTurn
  | -- | CR 611.2a: "during that player's next turn" -- a WINDOW rather than a
    -- deadline. Ends where AtEndOfTurnOf above ends, off the same
    -- Parun.Types.AfterTurn and by the same reading, and BEGINS where AtTurnOf
    -- ends: the effect does nothing until that turn is under way.
    --
    -- One of the arms whose stored row is inert for part of its life (the
    -- others are DuringUntapStepOf and DuringExtraTurn below), which is why
    -- Parun.Engine.Expiry.begun exists beside the sweeps -- a reader that asks
    -- only "has this ended" sees this row from the moment it is stored and
    -- applies it a turn early.
    --
    -- Six carriers ask `begun`: GameState.attackProhibitions (Wall of Dust),
    -- GameState.attackRequirements (Taunt, Gideon, Battle-Forged),
    -- GameState.playerEffects (Sphinx's Decree), Object.playableFromExile
    -- (Galvanic Relay), GameState.replacements (False Peace) and
    -- GameState.objectProhibitions (Exhaustion). A row on any
    -- other would apply from the moment it is stored, so Parun.EffectLintSpec's
    -- windowOffends refuses a card writing one (Scryfall o:/during [^.]*next
    -- turn/, 2026-10-11: every hit is one of the first four or CR 723's player
    -- control).
    DuringTurnOf AfterTurn.AfterTurn
  | -- | CR 611.2a: Duration.DuringNextUntapStepOf, stored -- a WINDOW, open while
    -- this player's untap step is under way and ended as it ends. A third arm
    -- whose stored row is inert for part of its life (Parun.Engine.Expiry.begun).
    DuringUntapStepOf PlayerId.PlayerId
  | -- | CR 611.2a: DuringTurnOf with its seat not yet known -- "during its
    -- controller's next turn", open on any later turn while that object's
    -- current controller is active, pinned to DuringTurnOf once such a turn's
    -- declare attackers step ends (Parun.Engine.Expiry.pinAfterDeclareAttackers),
    -- and ended by such a turn's cleanup if it had none.
    -- Wall of Dust and Gideon, Battle-Forged are the producers.
    DuringTurnOfControllerOf AfterObjectTurn.AfterObjectTurn
  | -- | CR 611.2a / 500.7: Duration.DuringThatExtraTurn, stored as the
    -- ExtraTurn.createdAt of the turn it names. A window like DuringTurnOf
    -- above, inert until that turn is under way (Parun.Engine.Expiry.begun), and
    -- meaningful only on a carrier that asks `begun`: GameState.playerEffects
    -- is where both producers (Alchemist's Gambit, All in Good Time) store it.
    DuringExtraTurn Timestamp.Timestamp
  | -- | CR 500.5: effects lasting until the end of a step or phase expire as it
    -- ends. A Parun.Types.PhaseSelector because CR 500.5 names both grains and
    -- that type spans both.
    --
    -- Matched by EQUALITY against the ending window, so a selector naming the
    -- combat phase is never confused with one naming a step of it -- CR 500.5a
    -- puts "until end of combat" at the end of the combat PHASE, so the end of
    -- combat step's own end does not reach an AtEndOf CombatPhase entry.
    --
    -- Only the CombatPhase arm has a printed producer today
    -- (Duration.UntilEndOfCombat, Jade Statue); the others cost nothing.
    AtEndOf PhaseSelector.PhaseSelector
  | -- | CR 500.5a / 611.2a: Duration.UntilEndOfCombatOnYourNextTurn, stored.
    AtEndOfCombatOn AfterTurn.AfterTurn
  | -- | CR 611.2a / 116.2c: ends when a player pays this cost, which they may do
    -- "any time they have priority ... for as long as the effect allows it". The
    -- stored counterpart of Duration.UntilPaid.
    --
    -- Survives every sweep in Parun.Engine.Expiry, as Never does -- no window of
    -- the turn ends it. It is a separate arm from Never all the same, and the
    -- reason is IDENTITY rather than lifetime: Parun.Engine.EndEffect has to find
    -- the stored effects one payment ends, and it finds them by this arm plus the
    -- effect's source. A Never entry names no price and belongs to no offer, so
    -- it cannot be told from any other end-of-game effect the same object made.
    --
    -- Carries the COST for the same reason Duration.UntilPaid does: it is what
    -- the offer quotes and what the payment charges. Both halves of one printed
    -- sentence therefore end together -- every effect the resolution stored
    -- carries this same arm and the same source.
    --
    -- Carries the SEAT beside it, as While above does: CR 109.5's "you" is the
    -- player who activated the ability or controlled the spell, so the offer is
    -- baked at arming time rather than re-read off the source's current
    -- controller. A
    -- Licid taken by Confiscate after it animated itself is the board that tells
    -- the two apart.
    WhenPaid PaidExpiry.PaidExpiry
  | -- | CR 611.2a / Quicken, Scout's Warning: ends the moment the effect it
    -- carries is exercised, not at a moment the clock could name. Also ends at
    -- cleanup like AtCleanup, since every printed producer also says "this
    -- turn"; Parun.Engine.PlayerEffect.spentByCast/spentByLandPlay and a
    -- delayed trigger's firing (Parun.Engine.Expiry.firesOnce) end it early.
    -- The slot is Duration.UntilUsed's, carried to the use that binds it.
    WhenUsed (Maybe SlotName.SlotName)
  | -- | CR 611.2a: Duration.UntilEvent, stored. Ends when its event happens,
    -- and never resumes: a Vesuvan Shapeshifter turned face up again by other
    -- means does not bring its effect back.
    OnEvent EventExpiry.EventExpiry
  deriving (Eq, Ord, Show)
