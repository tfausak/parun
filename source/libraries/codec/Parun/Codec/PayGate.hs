{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.PayGate where

import qualified Data.List.NonEmpty as NonEmpty
import qualified Parun.Codec.ClauseIndex as ClauseIndex
import qualified Parun.Codec.Cost as Cost
import qualified Parun.Codec.CostBasis as CostBasis
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.PayBranch as PayBranch
import qualified Parun.Codec.PayObligation as PayObligation
import qualified Parun.Codec.PlayerRef as PlayerRef
import qualified Parun.Codec.Quantity as Quantity
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.CostChoice as CostChoice
import qualified Parun.Types.PayGate as PayGate
import qualified Parun.Types.PayObligation as PayObligation

-- | The first three keys are required: a gate with no payer names nobody, one
-- with no cost offers nothing, and one with no branch does not say which half of
-- CR 118.12 it is. None has a default an absent key could mean -- least of all
-- the branch, where a default would let a card written a word short play as the
-- opposite card.
--
-- The other six are elided when unmarked, which is what every card but
-- Standstill and Don't Make a Sound writes: CR 118.12a's rewriting makes an
-- "unless" cost optional, a clause that names no other clause makes its own
-- offer, and a cost is offered once rather than once per counted thing.
-- Rakshasa's Disdain is the card in `data/cards/` that writes `perEach`; CR
-- 702.24a's mint writes one too, but a minted ability never goes on the wire.
-- `basis` is Flash's alone: CR 118.6 lets a cost be described in terms of
-- another object's mana cost rather than printed, and every other gate prints
-- one. `x` is Flameblast Dragon's: an {X} chosen as the ability resolves (CR
-- 107.3f) rather than announced.
--
-- `cost` is the gate's first option and `orCosts` the rest, in printed order
-- (Parun.Types.PayGate.cost), so a one-option gate writes no list.
codec :: Codec.Codec PayGate.PayGate
codec = Fields.object $ do
  payer <- Fields.required "payer" PlayerRef.codec PayGate.payer
  cost <- Fields.required "cost" (Cost.codec Keyword.codec) (NonEmpty.head . CostChoice.unwrap . PayGate.cost)
  orCosts <- Fields.defaulted "orCosts" [] (Common.list (Cost.codec Keyword.codec)) (NonEmpty.tail . CostChoice.unwrap . PayGate.cost)
  basis <- Fields.defaulted "basis" Nothing (Common.maybe CostBasis.codec) PayGate.basis
  branch <- Fields.required "branch" PayBranch.codec PayGate.branch
  obligation <- Fields.defaulted "obligation" PayObligation.Optional PayObligation.codec PayGate.obligation
  perEach <- Fields.defaulted "perEach" Nothing (Common.maybe Quantity.codec) PayGate.perEach
  x <- Fields.defaulted "x" Nothing (Common.maybe Quantity.codec) PayGate.x
  offeredAt <- Fields.defaulted "offeredAt" Nothing (Common.maybe ClauseIndex.codec) PayGate.offeredAt
  pure
    PayGate.MkPayGate
      { PayGate.payer = payer,
        PayGate.cost = CostChoice.MkCostChoice (cost NonEmpty.:| orCosts),
        PayGate.basis = basis,
        PayGate.branch = branch,
        PayGate.obligation = obligation,
        PayGate.perEach = perEach,
        PayGate.x = x,
        PayGate.offeredAt = offeredAt
      }
