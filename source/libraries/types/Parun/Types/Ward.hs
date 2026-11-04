module Parun.Types.Ward where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.KeywordCount as KeywordCount

-- | The payload of Parun.Types.Keyword's Ward arm: CR 702.21a's cost, plus CR
-- 702.21b's X as a second field on it.
--
-- PARAMETRIC in the keyword, Parun.Types.Cycling's reason: the cost can name a
-- Keyword and Keyword names THIS. Only @Ward Keyword.Keyword@ is ever written.
data Ward keyword = MkWard
  { -- | CR 702.21a's [cost]. Raffine, Scheming Seer's is {1}, Auntie Ool,
    -- Cursewretch's is a blight. With @perEach@ set this is the cost of ONE of
    -- the things counted, so ward {X} writes {1} here.
    cost :: Cost.Cost keyword,
    -- | CR 702.21b's "some ward abilities include an X in their cost and state
    -- what X is equal to", as a multiplier on the cost above rather than as an
    -- {X} symbol inside it: ward {X} is X copies of {1}, and one copy of a cost
    -- per thing counted is exactly Parun.Types.PayGate's perEach, which
    -- Parun.Engine.Resolve.Effect.payGatePaidBy evaluates against the RESOLUTION. CR
    -- 107.4b is why the two spellings are one charge -- every generic symbol is
    -- payable with any type of mana, so X copies of {1} and a {X} standing for
    -- the same number take the same mana. That
    -- is what rule 702.21b asks for -- "this value is determined at the time the
    -- ability resolves, not locked in as the ability triggers" -- and it is why
    -- the value cannot ride Cost's own {X}, whose value CR 107.3a fixes at what
    -- CR 601.2b announced (Parun.Engine.Resolve.Common.announcedXOn).
    --
    -- A Parun.Types.KeywordCount, the N mobilize and firebending restate, and
    -- NOT the Parun.Types.Quantity that Parun.Engine.Keyword.keywordCount widens
    -- it into: Quantity names Keyword, and Keyword names this. Minthara,
    -- Merciless Soul's counts player counters; Phyrexian Fleshgorger's "pay life
    -- equal to this creature's power" is PayLife 1 per point of Power.
    --
    -- Nothing is every other printing: a ward whose cost is a printed number.
    --
    -- The "CR 702.21b" scenarios under data/scenarios/ prove the
    -- resolution-time read.
    perEach :: Maybe (KeywordCount.KeywordCount keyword)
  }
  deriving (Eq, Ord, Show)
