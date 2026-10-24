module Parun.Types.PayOffer where

import qualified Parun.Types.ClauseIndex as ClauseIndex
import qualified Parun.Types.ModeIndex as ModeIndex
import qualified Parun.Types.Recipient as Recipient

-- | Which offer an object is making, so the payer can tell one offer from
-- another.
data PayOffer
  = -- | A clause's own gate, by CR 608.2e's mode and clause ordinals.
    AtClause ModeIndex.ModeIndex ClauseIndex.ClauseIndex
  | -- | A CR 608.2f loop's gate, offered once per member (Cleansing's "for each
    -- land ... unless any player pays 1 life").
    ForMember Recipient.Recipient
  | -- | A draw replacement's offer (CR 614.6), Zur's Weirding's "any other player
    -- may pay 2 life"; the offering object is the replacement's source.
    InsteadOfDraw
  deriving (Eq, Ord, Show)
