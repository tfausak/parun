module Parun.Types.AnyNumberOf where

-- | What a Parun.Types.Prompt.ChooseAnyNumber answer is for: which objects were
-- offered and what is done to the ones named.
data AnyNumberOf
  = -- | CR 608.2d: the matching permanents, or exiled cards, a resolving effect
    -- acts on or binds (Parun.Types.ChosenPermanents at HowMany.UpTo). Not
    -- targets (CR 115.1, CR 115.10a).
    Permanents
  | -- | CR 608.2d: the cards of a bound group an "up to" ChosenCardFromAmong
    -- takes.
    CardsFromAmong
  | -- | CR 608.2d: the cards in the asked seat's own hand an "up to"
    -- Parun.Types.ChosenCardInHand takes.
    CardsInHand
  | -- | CR 614.1c / 614.13a: the permanents sacrificed as a permanent enters.
    ToSacrifice
  | -- | CR 702.38a / 701.20a: the cards in hand revealed as a permanent enters.
    ToReveal
  | -- | CR 614.1c / 614.13a: the graveyard cards exiled as a permanent enters.
    ToExile
  | -- | CR 701.9b / 107.1c: the cards in the asked seat's own hand it discards
    -- (Parun.Types.AnyNumberDiscard).
    ToDiscard
  | -- | The Unstable FAQ: the Contraptions on the sprocket the CRANK! counter
    -- reached that their controller cranks.
    ToCrank
  | -- | CR 700.3: the permanents or cards a player puts into one of two piles, the rest
    -- of the offer forming the other.
    IntoPile
  | -- | CR 502.3: the permanents the active player may leave tapped, or a cap
    -- counts (Parun.Types.UntapHold's Elective and AtMost), that they untap, the
    -- rest staying tapped.
    ToUntap
  deriving (Bounded, Enum, Eq, Ord, Show)
