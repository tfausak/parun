module Parun.Types.AttachmentEnd where

-- | CR 701.3: which end of an attachment link the bearer of a trigger is.
data AttachmentEnd
  = -- | The permanent attached to (Bramble Elemental's "this creature").
    Host
  | -- | The permanent doing the attaching (Enormous Energy Blade's "this
    -- Equipment").
    Attachment
  deriving (Bounded, Enum, Eq, Ord, Show)
