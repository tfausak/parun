module Pawl.Types.PlayerInstruction where

-- | What a player is instructed to do some number of times, as
-- Pawl.Types.ProposedEvent's WouldPerform proposes it and
-- Pawl.Types.InstructionR's rows name it (CR 614.1a). Each constructor's
-- comment names the funnel that raises it.
--
-- A sibling of Pawl.Types.PlayerAction rather than more of its arms: that type
-- is what a CR 603.2 trigger watches, recorded as GameEvent.PlayerActed, and a
-- draw, a mill or a coin flip is recorded as an event of its own carrying the
-- result -- so a PlayerActs trigger on one would decode and never fire.
data PlayerInstruction
  = -- | CR 121.2a: draw this many cards. Raised once per drawer before any of
    -- CR 121.2's individual draws -- rule 616.1g's containment: the instruction
    -- is settled here, then each draw it leaves raises its own WouldDraw. The
    -- count is the number the instruction NAMES, never a library or a hand size.
    -- CR 121.1's turn-based draw raises none, drawing one card, nor does CR
    -- 103.5's opening hand, which runs before any replacement can exist.
    DrawCards
  | -- | CR 701.17a: mill this many cards. Raised by Pawl.Engine.Event.millFrom,
    -- the one funnel every mill goes through, for a positive count only. One
    -- event for the whole instruction, since rule 701.17a moves the cards at
    -- once; CR 701.17b's "as many as possible" is read off the settled count when
    -- the cards are taken.
    MillCards
  | -- | CR 705.1: flip one coin, settled with this many coins. Raised by
    -- Pawl.Engine.Event.flipOneCoin once per flip, Krark's Thumb's ruling scoping
    -- its replacement to "each individual coin flip"; the flipper is CR 705.2's
    -- only involved seat. Also the event a d20 roll becomes inside its own CR
    -- 616.1 loop when Pokey, the Scallywagg flips instead
    -- (DieRollRewrite.FlipCoinInstead).
    FlipCoin
  | -- | CR 701.34a: proliferate this many times. Raised once per instruction by
    -- Pawl.Engine.Resolve.Effect's Proliferate arm.
    Proliferate
  | -- | CR 701.22a: scry this many cards. Raised by Pawl.Engine.Resolve.Effect's
    -- Scry arm for a positive count only, CR 701.22b's scry 0 being no scry.
    Scry
  | -- | CR 701.55a / 701.55c: face a villainous choice this many times. Raised
    -- once per facing seat by Pawl.Engine.Resolve.villainousPass.
    FaceVillainousChoice
  | -- | The Unstable FAQ: assemble this many Contraptions. Raised once per
    -- instruction by Pawl.Engine.Contraption.assemble.
    Assemble
  deriving (Bounded, Enum, Eq, Ord, Show)
