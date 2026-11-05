-- CR 116.2c: the special action a Parun.Types.LaterPayment leaves its controller.
-- The offer and the payment; running what was paid for is
-- Parun.Engine.Resolve.Effect.runLaterPayment's, this module being below it.
module Parun.Engine.LaterPayment where

import qualified Control.Monad.Trans.State.Strict as State
import qualified Data.List as List
import qualified Parun.Engine.Cost as Cost
import qualified Parun.Types.ActiveLaterPayment as ActiveLaterPayment
import Parun.Types.Game (Game)
import Parun.Types.GameState (GameState)
import qualified Parun.Types.GameState as GameState
import qualified Parun.Types.ManaAbilityPerformer as ManaAbilityPerformer
import Parun.Types.ObjectId (ObjectId)
import qualified Parun.Types.PaymentSubject as PaymentSubject
import Parun.Types.PlayerId (PlayerId)
import qualified Parun.Types.PreventionRider as PreventionRider
import Parun.Types.Timestamp (Timestamp)

-- What this player may pay for right now, each as its source and its row, in
-- store order. No conjunct for priority, legalActions being asked only of its
-- holder (CR 116.2c), and none for the cost's CR 601.2f adjustments, a special
-- action being neither a cast nor an activation (EndEffect.canEnd's reason).
payable :: PlayerId -> GameState -> [(ObjectId, Timestamp)]
payable pid gs =
  [ (sourceOf row, ActiveLaterPayment.createdAt row)
  | row <- GameState.laterPayments gs,
    PreventionRider.controller (ActiveLaterPayment.payoff row) == pid,
    Cost.canPay PaymentSubject.ForNeither pid (sourceOf row) (ActiveLaterPayment.cost row) gs
  ]

sourceOf :: ActiveLaterPayment.ActiveLaterPayment -> ObjectId
sourceOf = PreventionRider.source . ActiveLaterPayment.payoff

-- CR 116.2c: pay this row's cost, answering what to run if it was paid. A payment
-- that fails restores the state from before it, EndEffect.endEffect's posture.
pay :: ManaAbilityPerformer.ManaAbilityPerformer -> PlayerId -> Timestamp -> Game (Maybe PreventionRider.PreventionRider)
pay perform pid createdAt = do
  before <- State.get
  case List.find ((== createdAt) . ActiveLaterPayment.createdAt) (GameState.laterPayments before) of
    Nothing -> pure Nothing
    Just row -> do
      paid <- Cost.payAction perform before PaymentSubject.ForNeither 0 pid (sourceOf row) (ActiveLaterPayment.cost row)
      pure (ActiveLaterPayment.payoff row <$ paid)
