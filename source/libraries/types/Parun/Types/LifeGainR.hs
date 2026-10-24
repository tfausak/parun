module Parun.Types.LifeGainR where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.LifeGainRewrite as LifeGainRewrite

-- | The payload of Parun.Types.ReplacementEffect's LifeGainR arm: whose life
-- gains are intercepted (CR 119.10 / 614.1a), and what happens instead.
--
-- A bare ControllerRelation rather than a pattern RECORD, Parun.Types.DrawR's
-- shape rather than Parun.Types.LifeLossPattern's: the loss side needs a cause
-- field because Worship's clause says "damage that would reduce your life
-- total", and no printed gain clause narrows that way -- Boon Reflection, Rhox
-- Faithmender and Alhammarret's Archive all say "if you would gain life" flat.
-- The record appears when a card needs one.
data LifeGainR = MkLifeGainR
  { whose :: ControllerRelation.ControllerRelation,
    rewrite :: LifeGainRewrite.LifeGainRewrite
  }
  deriving (Eq, Ord, Show)
