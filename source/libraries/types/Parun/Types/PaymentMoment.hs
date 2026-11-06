module Parun.Types.PaymentMoment where

-- | WHEN a cost is being paid, at the one grain the rules make anything depend
-- on: is a spell or ability resolving, whose cause the payment's events keep?
--
-- A cost paid under CR 601.2h -- while a spell is being cast or, through CR
-- 602.2b, an ability activated -- causes nothing, and neither does CR 508.1j's
-- or CR 509.1f's combat toll. A cost paid under CR 118.12, as the spell or
-- ability RESOLVES, keeps the resolving object's cause, though it is still a
-- cost and no effect (docs/decisions.md, "Whether a cost paid on resolution is
-- an effect").
--
-- Carried into Parun.Engine.Cost.pay rather than derived there, because nothing
-- about a cost says which moment it is being paid at: Soul Immolation's "blight
-- X" and Boggart Mischief's "unless you blight 1" are the same
-- Parun.Types.CostComponent, and only the caller knows which door it came in by.
--
-- Read by Parun.Engine.Cost.payComponent, for whether the payment's events
-- record a cause.
data PaymentMoment
  = -- | CR 601.2h's payment, and CR 508.1j \/ 509.1f's combat toll: no spell or
    -- ability is resolving.
    OutsideResolution
  | -- | CR 118.12's payment, made as the spell or ability resolves.
    DuringResolution
  deriving (Eq, Ord, Show)
