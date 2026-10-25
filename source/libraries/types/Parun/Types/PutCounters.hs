module Parun.Types.PutCounters where

import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Quantity as Quantity

-- | The payload of Parun.Types.Effect's PutCounters arm (#1305). The
-- `quantity` is read per permanent, so a division's part (Quantity.Share) is
-- each one's own: Crashing Wave's "distribute three stun counters" is an
-- Effect.Divide and then this (CR 608.2d).
--
-- An ObjectRef rather than a bare slot, so that Renegade Krasis' "each other
-- creature you control with a +1/+1 counter on it" can be written: CR 115.10a
-- makes such a set a description and never a target, which is exactly the
-- distinction that type draws.
--
-- ONE kind per instruction, which is all CR 701.10e's sentence asks for and what
-- Aragorn, Hornburg Hero writes. A card's "each kind of counter" (Vorel of the
-- Hull Clade) is Parun.Types.PutCountersFrom from a permanent onto itself.
--
-- Each named permanent gets its OWN call to Event.putCounters, because CR 614.16
-- replaces one placement at a time: a Hardened Scales seeing three creatures gets
-- three opportunities, not one.
data PutCounters = MkPutCounters
  { kind :: CounterKind.CounterKind Keyword.Keyword,
    quantity :: Quantity.Quantity,
    ref :: ObjectRef.ObjectRef
  }
  deriving (Eq, Ord, Show)
