module Parun.Codec.CounterHolderSpec where

import qualified Parun.Codec.CounterHolder as CounterHolder
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CounterHolder as CounterHolder
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterHolder" $ do
  Spec.it s "Self" $
    Common.assertCodec
      s
      CounterHolder.codec
      CounterHolder.Self
      " {\"type\":\"Self\"} "
  -- Wickersmith's Tools' "on a creature".
  Spec.it s "Permanent" $
    Common.assertCodec
      s
      CounterHolder.codec
      (CounterHolder.Permanent (Filter.HasCardType CardType.Creature))
      " {\"type\":\"Permanent\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterHolder.codec
