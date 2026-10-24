module Parun.Types.TurnUpRewrite where

import qualified Parun.Types.AsCopy as AsCopy
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.WithCounters as WithCounters

-- | CR 614.1e: how an "As [this permanent] is turned face up . . ." replacement
-- modifies the turning-over. EntryRewrite's twin one event class over, and a
-- separate type rather than a reuse of it: CR 614.1c's rewrites include entering
-- under another player's control (CR 616.1b) and entering tapped (CR 110.5b),
-- neither of which a permanent already on the battlefield can be made to do by
-- turning over. Becoming a copy it can (CR 707.4), so that arm shares
-- EntryRewrite's payload.
--
-- One constructor per shape the pool prints. CR 208.2b names another the
-- rules allow -- a static ability that "sets the creature's power and toughness
-- ... as it enters the battlefield or is turned face up" -- and that is a
-- constructor here plus a layer-1a write, not a change to either of these.
data TurnUpRewrite ability effect
  = -- | CR 702.37b: "put a +1/+1 counter on it". The kind and the count ride the
    -- constructor, as EntryRewrite.WithCounters' do, and the counters are placed
    -- through Parun.Engine.Event.putCounters -- CR 122.6's funnel -- so CR 614.16
    -- applies and Doubling Season doubles a megamorph's counter.
    WithCounters WithCounters.WithCounters
  | -- | CR 303.4k: "you may attach it to a creature" (Gift of Doom), the one
    -- printing of the "effect [that] allows an Aura that's being turned face up
    -- to become attached" that rule is conditional on.
    --
    -- The Filter is the card's own destination TEXT and nothing more -- "a
    -- creature" -- because CR 303.4k supplies the rest itself: "the Aura's
    -- controller considers the characteristics of that Aura as it would exist if
    -- it were face up ... and they must choose a legal object or player
    -- according to the Aura's enchant ability". Parun.Engine.Attach.turnUpHosts
    -- adds that enchant-ability conjunct, which is why Filter.CanHostSubject
    -- does not appear in the card data and must not be written into it. That is
    -- the difference from Effect.AttachTarget, where the narrowing happens only
    -- when the card SAYS "it can enchant" and CR 303.4j is the backstop
    -- otherwise: rule 303.4k leaves no such backstop open.
    --
    -- A "MAY", spelled into the constructor's name rather than carried as a
    -- flag, because that is the only form CR 303.4k's producer takes. A
    -- mandatory one would be a second constructor.
    MayAttachTo (Filter.Filter Keyword.Keyword)
  | -- | CR 707.4 / 708.11: "as this creature is turned face up, you may choose
    -- another creature ... it becomes a copy of that creature" (Vesuvan
    -- Shapeshifter). EntryRewrite.AsCopy's payload, read the same way except
    -- that nothing enters: CR 614.1d's `tapped` and CR 707.9e's `counters`
    -- are entry riders, which Parun.CardSpec holds no turn-up row states.
    AsCopy (AsCopy.AsCopy ability effect)
  deriving (Eq, Ord, Show)
