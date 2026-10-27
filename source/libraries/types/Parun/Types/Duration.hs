module Parun.Types.Duration where

import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.DurationEvent as DurationEvent
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.SlotName as SlotName

-- | How long a stored continuous effect lasts, as the CARD says it (CR 611.2).
-- PRINTED data: this is what appears in card JSON. The game stores
-- Parun.Types.Expiry instead, and Parun.Engine.Expiry.arm is the one-way door between
-- them. A static ability's effect normally carries no Duration -- it lasts
-- while its source and ability do, which is "while re-derived from the
-- battlefield" -- and the one exception is StaticAbility.lingers, the clause
-- that gives such an effect a duration to keep running out AFTER its permanent
-- has gone.
data Duration
  = UntilEndOfTurn -- CR 514.2
  | Indefinite -- CR 611.2a: "lasts until the end of the game" (Magical Hack)
  | -- | Alchemy's "perpetually" (Pearl Collector): Indefinite's lifetime, plus
    -- following its objects across CR 400.7's new object.
    Perpetual
  | -- | CR 611.2a: "until your next turn" (Hag of Inner Weakness). "Your" is
    -- resolved to a concrete player by Parun.Engine.Expiry.arm (CR 109.5) -- it cannot
    -- be a PlayerId here, because a printed card does not know one.
    UntilYourNextTurn
  | -- | CR 611.2a: "until the beginning of your next upkeep" (Grinning
    -- Totem), "until your next end step" (Haste Magic): ends as that step of
    -- your turn next begins. "Your" is resolved the way the arm above's is.
    UntilYourNextStep Phase.Phase
  | -- | CR 611.2a: "until the end of your next turn" (Soulfire Eruption), which
    -- ends a whole turn later than the arm above: as that turn ENDS, in its
    -- cleanup step (CR 514), rather than as it begins. Both "your"s are resolved
    -- the same way, by Parun.Engine.Expiry.arm.
    UntilEndOfYourNextTurn
  | -- | CR 611.2a: "until the end of their next turn" (Suspend Aggression), where
    -- the seat is named by a reference rather than being CR 109.5's "you".
    --
    -- The arm above's window with the seat spelled out, and never derivable from
    -- it: CR 109.5 fixes that one to the effect's controller, and the exiled
    -- card Suspend Aggression hands back belongs to whoever owned it.
    -- Parun.Engine.Expiry.arm samples the reference ONCE, as the duration begins,
    -- so the stored Parun.Types.AfterTurn holds a seat and not a reference.
    --
    -- A reference naming several seats, or Candidate outside the fold
    -- Parun.Engine.Expiry.perSeat serves, names no one turn and arms nothing
    -- (Parun.Engine.Expiry.seatOf).
    UntilEndOfNextTurnOf PlayerRef.PlayerRef
  | -- | CR 611.2a: "during that player's next turn" (Wall of Dust) -- a WINDOW,
    -- where every arm above states only an end. The effect applies during that
    -- one turn and not before it, so the seat's intervening exposure is exactly
    -- what tells this arm from UntilEndOfNextTurnOf above.
    --
    -- The seat is a reference, as that arm's is, and is sampled the same way and
    -- at the same moment (Parun.Engine.Expiry.arm, Parun.Engine.Expiry.seatOf).
    -- Candidate is "that player" of a fold -- Sphinx's Decree's "each opponent
    -- can't cast instant or sorcery spells during that player's next turn" --
    -- and arms one window per member (Parun.Engine.Expiry.perSeat).
    DuringNextTurnOf PlayerRef.PlayerRef
  | -- | CR 611.2a / 502.3: "during their next untap step" (Exhaustion) -- a
    -- WINDOW, the arm above's with the untap step for the turn, its seat sampled
    -- the same way.
    DuringNextUntapStepOf PlayerRef.PlayerRef
  | -- | CR 611.2a: "during your next turn" (Galvanic Relay) -- the arm above's
    -- window with the seat taken from CR 109.5's "you" instead of sampled from a
    -- reference, as UntilYourNextTurn stands to UntilEndOfNextTurnOf.
    --
    -- Nullary, as UntilYourNextTurn is: CR 109.5's "you" is the effect's
    -- controller, which Parun.Engine.Expiry.arm already holds.
    DuringYourNextTurn
  | -- | CR 611.2a / 500.7: "during that turn", the extra turn the same resolution
    -- created (Alchemist's Gambit) -- named by its ExtraTurn.createdAt, as
    -- Onset.FromThatExtraTurn names it, since a later-created extra turn is
    -- taken first.
    DuringThatExtraTurn
  | -- | CR 611.2b: "for as long as ...". The duration has a BEGINNING as well as
    -- an end -- "if the 'for as long as' duration never starts, the effect does
    -- nothing" -- which is why Parun.Engine.Expiry.arm returns a Maybe.
    ForAsLongAs Condition.Condition
  | -- | CR 500.5a / 511.2: expires at the end of the combat PHASE, not at the
    -- beginning of the end of combat step. Jade Statue's animation.
    --
    -- Nullary, and the only CR 500.5 WINDOW a card can print: the stored
    -- Parun.Types.Expiry it arms to can name any window that rule can end, but no
    -- card in the pool prints the others (#353).
    --
    -- WHICH combat phase is not carried. CR 500.8 permits more than one in a
    -- turn, and the sweep ends this effect at the first whose end it sees; every
    -- producer arms it during combat, so that is the phase the effect was
    -- created in. The one printed duration armed outside combat names its turn,
    -- and is the arm below.
    UntilEndOfCombat
  | -- | CR 500.5a / 611.2a: "until end of combat on your next turn" (Brazen
    -- Cannonade), stored as Expiry.AtEndOfCombatOn.
    UntilEndOfCombatOnYourNextTurn
  | -- | CR 611.2a: "You may pay {U} to end this effect", the clause every Licid
    -- prints. The duration a spell or ability states need not be a window of the
    -- turn at all -- this one ends when a player takes CR 116.2c's special
    -- action, which Parun.Types.Action's EndEffect carries and
    -- Parun.Engine.EndEffect performs.
    --
    -- The COST rides here because CR 116.2c fixes neither price nor timing: "for
    -- as long as the effect allows it", and the effect is this. All twelve Licids
    -- say one mana symbol, but the field is a whole Parun.Types.Cost --
    -- SpecialAction.IgnoreThisUntilEndOfTurn's shape one rule over, so the two
    -- pay-to-take actions are paid through one Parun.Engine.Cost call.
    --
    -- No sweep of Parun.Engine.Expiry ends it: the stored counterpart
    -- (Expiry.WhenPaid) is what the special action looks for, and nothing about
    -- the turn's structure ends it. Indefinite is therefore the WRONG arm for a
    -- Licid even though both outlast every window -- an Expiry.Never cannot be
    -- keyed on, so the performer could not find the effects the payment ends.
    UntilPaid (Cost.Cost Keyword.Keyword)
  | -- | CR 611.2a / Quicken: "the next ... you ... this turn", stored as
    -- Expiry.WhenUsed. The slot, when present, is Savage Summoning's "that
    -- spell": the spell whose cast uses the effect up, bound into the other rows
    -- the same source installed (Parun.Engine.Cast.bindUser).
    UntilUsed (Maybe SlotName.SlotName)
  | -- | CR 611.2a: "until" an event -- "this creature is turned face down"
    -- (Vesuvan Shapeshifter), "a player casts a creature spell" (Soul
    -- Sculptor) -- stored as Expiry.OnEvent.
    UntilEvent DurationEvent.DurationEvent
  deriving (Eq, Ord, Show)
