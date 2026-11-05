module Parun.Types.BecomesTargetedTrigger where

import qualified Parun.Types.ActingPermanent as ActingPermanent
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.StackObjectKind as StackObjectKind

-- | CR 601.2c: which permanents becoming targets fire the ability, by which
-- announcement road, and per permanent or per batch (CR 603.2c).
--
-- Fields rather than constructors, Parun.Types.ControllerBecomesTarget's shape:
-- every one narrows one rule 601.2c announcement and they differ only in how far.
data BecomesTargetedTrigger = MkBecomesTargetedTrigger
  { -- | The permanent the condition watches: the bearer (CR 702.21a's ward), or
    -- one the Filter admits, read off CR 603.10's sample of the battlefield at
    -- the announcement (Event.becameTarget).
    permanent :: ActingPermanent.ActingPermanent,
    -- | How the TARGETING object's controller (CR 405.4, recorded on
    -- Parun.Types.BecameTarget) stands to CR 109.5's "you", the sibling
    -- Parun.Types.ControllerBecomesTarget's field. AnyPlayer is Venerated
    -- Rotpriest's unnarrowed "a spell"; Opponent is ward's and Diffusion
    -- Sliver's.
    relation :: PlayerRelation.PlayerRelation,
    -- | Which of CR 601.2c's announcement roads, the sibling
    -- Parun.Types.ControllerBecomesTarget's field one recipient over. Nothing is
    -- "a spell or ability"; Just ActivatedAbility is Professor Hojo's.
    kind :: Maybe StackObjectKind.StackObjectKind,
    -- | Whether CR 109.5's "you" becoming a target counts too: Leyline of
    -- Combustion's "you and/or at least one permanent you control" (one batch,
    -- CR 603.2c) and Unsettled Mariner's "you or a permanent you control" (one
    -- occurrence each).
    includesYou :: Bool,
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
    { permanent = ActingPermanent.Self,
      relation = PlayerRelation.AnyPlayer,
      kind = Nothing,
      includesYou = False,
      batching = Batching.EachOccurrence
    }

-- | "Whenever a [permanent] becomes the target of a spell or ability": a
-- permanent the Filter admits, once per permanent.
matching :: Filter.Filter Keyword.Keyword -> BecomesTargetedTrigger
matching f = defaultValue {permanent = ActingPermanent.Matching f}
