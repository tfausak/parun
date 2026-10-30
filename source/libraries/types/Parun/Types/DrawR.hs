module Parun.Types.DrawR where

import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.DrawRewrite as DrawRewrite

-- | The payload of Parun.Types.ReplacementEffect's DrawR arm: whose card draws are
-- intercepted (CR 121.6 / 614.11), and what happens instead.
--
-- A bare ControllerRelation rather than a pattern RECORD, unlike
-- Parun.Types.LifeLossPattern: rule 121.1's draw carries no cause, no source and
-- no amount for a pattern record to narrow by, CR 121.2 having broken every
-- instruction into individual draws before a replacement sees one. The record
-- appears when a card needs one.
data DrawR = MkDrawR
  { whose :: ControllerRelation.ControllerRelation,
    -- | CR 504.1 / 614.1a: Chains of Mephistopheles' "except the first one they
    -- draw in each of their draw steps" -- the row does not apply to a draw by
    -- a player in their own draw step who has drawn no card since it began.
    exceptFirstInDrawStep :: Bool,
    rewrite :: DrawRewrite.DrawRewrite
  }
  deriving (Eq, Ord, Show)
