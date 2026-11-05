module Parun.Types.BecomesTargetedTrigger where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.TargetedSubject as TargetedSubject

-- | CR 601.2c: which targets becoming targets fire the ability, by which
-- announcement road, and per target or per batch (CR 603.2c).
--
-- Fields rather than constructors: every one narrows one rule 601.2c
-- announcement and they differ only in how far.
data BecomesTargetedTrigger = MkBecomesTargetedTrigger
  { -- | The targets the condition watches: the bearer (CR 702.21a's ward), a
    -- permanent the Filter admits, read off CR 603.10's sample of the
    -- battlefield at the announcement (Event.becameTarget), CR 109.5's "you"
    -- (Dormant Gomazoa), or "you or a permanent you control" (Leyline of
    -- Combustion, Unsettled Mariner).
    subject :: TargetedSubject.TargetedSubject,
    -- | How the TARGETING object's controller (CR 405.4, recorded on
    -- Parun.Types.BecameTarget) stands to CR 109.5's "you". AnyPlayer is
    -- Venerated Rotpriest's unnarrowed "a spell"; Opponent is ward's, Diffusion
    -- Sliver's and Amulet of Safekeeping's.
    relation :: PlayerRelation.PlayerRelation,
    -- | Which of CR 601.2c's announcement roads. Nothing is "a spell or
    -- ability"; Just Spell is Dormant Gomazoa's, so Ravenous Rats' targeted
    -- discard does not untap it; Just ActivatedAbility is Professor Hojo's.
    kind :: Maybe StackObjectKind.StackObjectKind,
    -- | Once per targeted permanent (Venerated Rotpriest) or once for the whole
    -- announcement (Professor Hojo's "one or more").
    batching :: Batching.Batching
  }
  deriving (Eq, Ord, Show)

-- | "Whenever this permanent becomes the target of a spell or ability": the
-- bearer, any player's, either road, once per announcement. The codec's
-- defaults.
defaultValue :: BecomesTargetedTrigger
defaultValue =
  MkBecomesTargetedTrigger
    { subject = TargetedSubject.Permanent ActingPermanent.Self,
      relation = PlayerRelation.AnyPlayer,
      kind = Nothing,
      batching = Batching.EachOccurrence
    }

-- | "Whenever a [permanent] becomes the target of a spell or ability": a
-- permanent the Filter admits, once per permanent.
matching :: Filter.Filter Keyword.Keyword -> BecomesTargetedTrigger
matching f = defaultValue {subject = TargetedSubject.Permanent (ActingPermanent.Matching f)}
