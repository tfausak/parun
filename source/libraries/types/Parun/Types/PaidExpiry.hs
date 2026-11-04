module Parun.Types.PaidExpiry where

import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

-- | CR 116.2c's pay-to-end offer, as the game remembers it: the price, the player
-- who may pay it, and the resolution that made it.

-- The PlayerId is the printed payer, BAKED at arming time (Parun.Engine.Expiry.arm)
-- for Parun.Types.While's reason and one of its own: a Licid's clause belongs to
-- an ACTIVATED ability, so rule 109.5 makes its "you" the player who activated
-- it, and a Licid whose control changes afterwards must not carry the offer over
-- to its new controller.
--
-- `resolution` is what a payment ends: every effect that one spell or ability
-- stored and nothing else from the same source, so Gliding Licid's one sentence
-- ends whole and each of Nafs Asp's hits stays its own debt.
data PaidExpiry = MkPaidExpiry
  { player :: PlayerId.PlayerId,
    cost :: Cost.Cost Keyword.Keyword,
    resolution :: ObjectId.ObjectId
  }
  deriving (Eq, Ord, Show)
