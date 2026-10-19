module Pawl.Types.CopyRecipient where

-- | Which object an "as" copy effect (Pawl.Types.AsCopy) makes a copy.
data CopyRecipient
  = -- | CR 707.5: the entering permanent itself (Clone).
    ThisObject
  | -- | CR 303.4m / 301.5f: whatever the permanent is attached to, for
    -- as long as it is (Metamorphic Alteration's "enchanted creature").
    ItsHost
  deriving (Bounded, Enum, Eq, Ord, Show)
