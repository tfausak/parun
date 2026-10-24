module Parun.Types.KeywordTally where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Scope as Scope

-- | The payload of Parun.Types.KeywordCount's Tally arm: Parun.Types.Count's scope
-- and filter, counted by members.
--
-- Not Parun.Types.Count itself, which names Keyword concretely and so cannot sit
-- inside one. PARAMETRIC in the keyword for Parun.Types.Devour's reason.
--
-- `filter` shadows the Prelude's, as Count's does.
data KeywordTally keyword = MkKeywordTally
  { scope :: Scope.Scope,
    filter :: Filter.Filter keyword
  }
  deriving (Eq, Ord, Show)
