module Parun.Types.UntapR where

import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.UntapRewrite as UntapRewrite

-- | The payload of Parun.Types.ReplacementEffect's UntapR arm: when a permanent's
-- untap is intercepted, and what happens instead.
data UntapR = MkUntapR
  { -- | CR 502.3: "during its controller's untap step" (Bewitching Leechcraft),
    -- as the step the game is in, its controller's own. Nothing is every untap
    -- (CR 122.1d).
    during :: Maybe Phase.Phase,
    rewrite :: UntapRewrite.UntapRewrite
  }
  deriving (Eq, Ord, Show)
