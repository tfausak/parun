module Parun.Types.KeywordRiderGrant where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.KeywordDesignator as KeywordDesignator
import qualified Parun.Types.RiderClause as RiderClause

-- | CR 602.5 relaxed by an effect: the player may activate the abilities a
-- rule-702 keyword is written on, of a matching permanent, past that clause of
-- the keyword's rider.
data KeywordRiderGrant = MkKeywordRiderGrant
  { -- | Which abilities, compared against
    -- Parun.Types.ActivatedAbility.keyword.
    abilities :: KeywordDesignator.KeywordDesignator Keyword.Keyword,
    relaxes :: RiderClause.RiderClause,
    -- | Which permanents, asked from the effect's source, so a holder relation
    -- of `You` is "creatures you control".
    permanents :: Filter.Filter Keyword.Keyword
  }
  deriving (Eq, Ord, Show)
