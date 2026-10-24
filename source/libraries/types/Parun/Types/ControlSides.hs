module Parun.Types.ControlSides where

import qualified Parun.Types.ControlSlots as ControlSlots
import qualified Parun.Types.SlotName as SlotName

-- | Which two permanents a control exchange runs between (CR 701.12b, whose
-- subject is control of TWO permanents; CR 701.12a is what makes an exchange
-- left with fewer than two sides do nothing). Read by Effect.ExchangeControl.
--
-- Parun.Types.ExchangeSides' shape over objects rather than players, and a
-- separate type because the unnamed side is a different thing: a life-total
-- exchange's is CR 109.5's "you", where this one is CR 113.7's source object.
-- Its own sum rather than a pair of Parun.Types.ObjectRefs for that type's
-- reason -- a ref may name every matching permanent at once, which an exchange
-- has nowhere to put, and the two sides of "two target creatures" come out of
-- ONE instance of the word "target" (CR 601.2c).
data ControlSides
  = -- | Both sides out of one slot naming exactly two permanents, targeted (CR 601.2c) or chosen (CR 608.2d).
    WithinSlot SlotName.SlotName
  | -- | Avarice Totem's "exchange control of this artifact and target nonland
    -- permanent": CR 113.7's source object and the one permanent the slot names.
    WithSource SlotName.SlotName
  | -- | Spawnbroker's "exchange control of target creature you control and target
    -- creature ... an opponent controls": one permanent out of each of two slots.
    BetweenSlots ControlSlots.ControlSlots
  deriving (Eq, Ord, Show)
