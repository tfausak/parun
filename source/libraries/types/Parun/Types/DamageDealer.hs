module Parun.Types.DamageDealer where

-- | Whose damage Parun.Types.DealtDamageTo asks about (CR 120.1).
data DamageDealer
  = -- | The candidate itself -- Brine Hag's "each creature that dealt damage to
    -- it".
    Candidate
  | -- | The evaluation's source -- Steel Hellkite's "dealt combat damage by this
    -- creature". CR 400.7's id, so a source that has since left still answers.
    Source
  deriving (Bounded, Enum, Eq, Ord, Show)
