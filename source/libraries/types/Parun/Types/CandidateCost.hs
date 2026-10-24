module Parun.Types.CandidateCost where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost

-- | CR 601.2b: one of the costs a spell may be cast for, together with WHAT
-- OFFERED IT.
--
-- The cost alone is not enough, because several rule 702 abilities condition
-- something AFTER the cast on which candidate was chosen: CR 702.34a's "if the
-- flashback cost was paid" and CR 702.133a's "if this spell was cast using its
-- jump-start ability" both exile the card as it leaves the stack, CR
-- 702.103b makes a spell cast bestowed an Aura enchantment, and CR 718.3b gives
-- a spell cast prototyped its inset frame's cost, box and colours. A bare
-- @Cost@ answers "what was paid" and never "which cost that was", and the two
-- come apart the moment a second permission offers the same card a second cost
-- from the same zone.
--
-- The tag is a Parun.Types.Keyword and not a Parun.Types.KeywordFamily because
-- jump-start and aftermath are NULLARY keywords, which that type deliberately
-- has no constructors for. Nothing means the candidate is the card's own
-- printed cost, one of its printed alternatives, or a cost an effect applied
-- (CR 118.9) -- in each case a cost no keyword ability offered.
--
-- Also what Prompt.ChooseCost offers and is answered with at every site, so
-- the answer names the candidate and not just its cost: Henzie "Toolbox"
-- Torre's blitz at a spell's own mana cost equals the printed cost and is a
-- different announcement (CR 601.2b, 702.152a). Sites where no keyword offers a
-- cost tag every candidate Nothing.
--
-- The keyword is the one READ IN THE ZONE the cast was proposed from (CR
-- 613.1), since that is where Parun.Engine.Cost.candidateCostsFor builds the
-- list: a granted flashback tags its candidate exactly as a printed one does.
data CandidateCost = MkCandidateCost
  { keyword :: Maybe Keyword.Keyword,
    cost :: Cost.Cost Keyword.Keyword,
    -- | CR 601.2f's reductions this candidate BRINGS WITH IT, on top of the ones
    -- the board states -- CR 702.119a's "if you chose to pay this spell's emerge
    -- cost, its total cost is reduced by an amount of generic mana equal to the
    -- sacrificed creature's mana value".
    --
    -- Here rather than folded into `cost`, because CR 601.2f applies every
    -- increase BEFORE any reduction: a candidate whose mana had the amount
    -- subtracted out would floor at {0} before a tax was added, and pay the tax in
    -- full. Parun.Engine.Cast.payableCostAt and Parun.Engine.Cast.castProposed both
    -- hand them to Parun.Engine.Cost.plusReductions, so the gate that offers the
    -- cast and the total that prices it cannot disagree.
    --
    -- Empty wherever the rule that offered it states no reduction. CR 702.48a's is the
    -- sacrificed permanent's whole mana cost, colored symbols included.
    reductions :: [ManaCost.ManaCost],
    -- | CR 702.48a: this candidate may be announced any time its caster could
    -- cast an instant, whatever the card's own window.
    instantSpeed :: Bool
  }
  deriving (Eq, Ord, Show)

-- | A candidate bringing no reduction and no window of its own.
plain :: Maybe Keyword.Keyword -> Cost.Cost Keyword.Keyword -> CandidateCost
plain k c = MkCandidateCost k c [] False
