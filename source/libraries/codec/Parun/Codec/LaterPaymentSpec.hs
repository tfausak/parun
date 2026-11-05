module Parun.Codec.LaterPaymentSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.LaterPayment as LaterPayment
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.LaterPayment as LaterPayment
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LaterPayment" $ do
  -- CR 116.2c: Guardian Angel's "until end of turn, you may pay {1}".
  Spec.it s "a duration, a cost and what a payment runs" $
    Common.assertCodec
      s
      (LaterPayment.codec Common.text)
      LaterPayment.MkLaterPayment
        { LaterPayment.duration = Duration.UntilEndOfTurn,
          LaterPayment.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.Generic 1]), Cost.components = []},
          LaterPayment.effects = Seq.singleton (Text.pack "shield")
        }
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"cost\":{\"mana\":[{\"type\":\"Generic\",\"value\":1}]},\"effects\":[\"shield\"]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s (LaterPayment.codec Common.text)
