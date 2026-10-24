module Parun.Types.Paying where

import qualified Parun.Types.Choices as Choices
import qualified Parun.Types.PaymentDecision as PaymentDecision

-- | CR 118.12a: an answer to an offered cost, and the choices paying it asks.
data Paying = MkPaying
  { decision :: PaymentDecision.PaymentDecision,
    choices :: Choices.Choices
  }
  deriving (Eq, Ord, Show)
