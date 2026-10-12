module Pawl.Types.Audience where

-- | CR 401.5 / 400.2: who a standing grant shows a player's cards to.
data Audience
  = -- | CR 400.2 / 401.5: every player, a reveal ("play with ... revealed").
    Everyone
  | -- | CR 400.2 / 401.5: that player alone, a look ("you may look at ...").
    ThatPlayer
  deriving (Bounded, Enum, Eq, Ord, Show)
