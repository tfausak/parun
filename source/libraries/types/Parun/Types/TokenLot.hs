module Parun.Types.TokenLot where

import qualified Numeric.Natural as Natural
import qualified Parun.Types.Card as Card
import qualified Parun.Types.ProjectedCharacteristics as ProjectedCharacteristics

-- | CR 111.1: some number of tokens of one shape, as one creation event would
-- make them. A Parun.Types.ProposedEvent.WouldCreateTokens carries a sequence
-- of these: one lot per effect until a replacement appends another
-- (Parun.Types.TokenR.plus).
data TokenLot = MkTokenLot
  { card :: Card.Card,
    -- | CR 707.1's copy token: the copied permanent's copiable values, which
    -- are what the token has from the instant it exists. Nothing for a token
    -- whose text is given.
    copy :: Maybe ProjectedCharacteristics.ProjectedCharacteristics,
    count :: Natural.Natural,
    -- | CR 614.16: an effect makes this lot -- a resolving spell's or
    -- ability's, or another replacement effect's. False for CR 118.12's cost,
    -- which is no effect (Library of Leng's ruling).
    byEffect :: Bool
  }
  deriving (Eq, Ord, Show)
