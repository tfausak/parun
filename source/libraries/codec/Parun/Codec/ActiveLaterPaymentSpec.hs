module Parun.Codec.ActiveLaterPaymentSpec where

import qualified Data.Map as Map
import qualified Data.Sequence as Seq
import qualified Parun.Codec.ActiveLaterPayment as ActiveLaterPayment
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveLaterPayment as ActiveLaterPayment
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Effect as Effect
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.PreventionRider as PreventionRider
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveLaterPayment" $ do
  -- CR 116.2c: a stored offer, with what a payment runs baked.
  Spec.it s "a price, a payoff, an identity and an expiry" $
    Common.assertCodec
      s
      ActiveLaterPayment.codec
      ActiveLaterPayment.MkActiveLaterPayment
        { ActiveLaterPayment.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 1]), Cost.components = []},
          ActiveLaterPayment.payoff =
            PreventionRider.MkPreventionRider
              { PreventionRider.effects = Seq.fromList [Effect.Proliferate],
                PreventionRider.targets = Map.empty,
                PreventionRider.controller = PlayerId.MkPlayerId 1,
                PreventionRider.source = ObjectId.MkObjectId 9
              },
          ActiveLaterPayment.createdAt = Timestamp.MkTimestamp 7,
          ActiveLaterPayment.expiry = Expiry.AtCleanup
        }
      " {\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"payoff\":{\"effects\":[{\"type\":\"Proliferate\"}],\"targets\":{},\"controller\":1,\"source\":9},\"createdAt\":7,\"expiry\":{\"type\":\"AtCleanup\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveLaterPayment.codec
