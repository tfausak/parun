module Parun.Types.Quotient where

import qualified Parun.Types.Rounding as Rounding

-- | The payload of Parun.Types.Arithmetic's Quotient arm: CR 107.1a's quotient,
-- rounded the way the card prints -- a half is a divisor of 2 (Malignus), and
-- Fireball's "X damage divided evenly, rounded down, among any number of
-- targets" divides by a count of them.
--
-- PARAMETRIC in the quantity for Parun.Types.Plus's reason: both operands are
-- whole Quantities and Quantity names this record.
--
-- The rounding is the CARD's word and never an engine rule -- Aspect of Wolf
-- prints both directions in one sentence -- which is why it rides the payload.
-- See Parun.Types.Rounding.
data Quotient quantity = MkQuotient
  { rounding :: Rounding.Rounding,
    -- | The dividend.
    quantity :: quantity,
    -- | What it is divided by; Parun.Engine.Quantity.divide says what a
    -- divisor of 0 or less answers.
    divisor :: quantity
  }
  deriving (Eq, Ord, Show)
