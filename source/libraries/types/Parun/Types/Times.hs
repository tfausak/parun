module Parun.Types.Times where

-- | The payload of Parun.Types.Arithmetic's Times arm: one quantity times
-- another (CR 107.1), which is how "you gain 3 life for each creature
-- attacking you" reads, its factor a literal, and how Angry Mob's "during your
-- turn" count reads, its factor Quantity.IsActivePlayer. No rounding word rides
-- here as it does on Parun.Types.Quotient: a whole number of a whole number is
-- a whole number.
--
-- PARAMETRIC in the quantity for Parun.Types.Quotient's reason: the inner value is
-- a whole Quantity and Quantity names this record.
data Times quantity = MkTimes
  { factor :: quantity,
    quantity :: quantity
  }
  deriving (Eq, Ord, Show)
