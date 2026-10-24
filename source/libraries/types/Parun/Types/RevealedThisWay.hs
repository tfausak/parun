module Parun.Types.RevealedThisWay where

import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.RevealTiming as RevealTiming

-- | CR 603.11 / 607.2h: the payload of Parun.Types.TriggerCondition's
-- RevealedThisWay arm -- what the bearer's own draw-time reveal must show, and,
-- where it matters, when.
--
-- Rowen's "whenever you reveal a basic land card this way" fires on either
-- timing, CR 121.8's deferred reveal included, so it states none. Booby Trap's
-- "when the chosen player draws a card with the chosen name" states AsDrawn: its
-- reveal covers every draw of that one player, so its own reveal shows each such
-- card as it is drawn, and a card kept face down by CR 121.8 has no
-- characteristics as it is drawn, so no name for its later reveal to answer with.
data RevealedThisWay = MkRevealedThisWay
  { card :: Filter.Filter Keyword.Keyword,
    timing :: Maybe RevealTiming.RevealTiming
  }
  deriving (Eq, Ord, Show)
