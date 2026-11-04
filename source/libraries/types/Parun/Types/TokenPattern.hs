module Parun.Types.TokenPattern where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword

-- | CR 111.1 / 614.1: which token creations a token replacement intercepts.
-- Doubling Season's token clause is Related You ("under your control") over any
-- token; Queen Allenal of Ruadach's narrows `whatToken` to creature tokens.
data TokenPattern = MkTokenPattern
  { whose :: ControllerRelation.ControllerRelation,
    -- | What the token being created IS, judged off the characteristics the
    -- creating effect gives it (CR 111.3). A creation of several lots matches
    -- when any lot does.
    whatToken :: Filter.Filter Keyword.Keyword,
    -- | CR 614.16: Doubling Season's "if an EFFECT would create". False for
    -- "if one or more tokens would be created", which also reaches a token
    -- made as a CR 118.12 cost, "costs aren't effects" (docs/decisions.md,
    -- "What a spell or ability causes").
    effectsOnly :: Bool
  }
  deriving (Eq, Ord, Show)
