module Parun.Codec.CounterTriggerSpec where

import qualified Parun.Codec.CounterTrigger as CounterTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CounterGrouping as CounterGrouping
import qualified Parun.Types.CounterHolder as CounterHolder
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.CounterMotion as CounterMotion
import qualified Parun.Types.CounterTrigger as CounterTrigger
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CounterTrigger" $ do
  -- Chandra, Fire Artisan: any loyalty removal from itself, so no defaulted key.
  Spec.it s "the defaults write no key" $
    Common.assertCodec
      s
      CounterTrigger.codec
      (CounterTrigger.MkCounterTrigger CounterKind.Loyalty CounterMotion.Removed CounterHolder.Self Nothing CounterGrouping.EachPermanent)
      " {\"kind\":{\"type\":\"Loyalty\"},\"motion\":{\"type\":\"Removed\"}} "
  -- CR 714.2b's chapter III.
  Spec.it s "a threshold writes its key" $
    Common.assertCodec
      s
      CounterTrigger.codec
      (CounterTrigger.MkCounterTrigger CounterKind.Lore (CounterMotion.Put PlayerRelation.AnyPlayer) CounterHolder.Self (Just 3) CounterGrouping.EachPermanent)
      " {\"kind\":{\"type\":\"Lore\"},\"motion\":{\"type\":\"Put\",\"value\":{\"type\":\"AnyPlayer\"}},\"threshold\":3} "
  -- Cloaked Cadet's "one or more +1/+1 counters are put on one or more
  -- creatures".
  Spec.it s "a holder and a grouping write their keys" $
    Common.assertCodec
      s
      CounterTrigger.codec
      (CounterTrigger.MkCounterTrigger CounterKind.PlusOnePlusOne (CounterMotion.Put PlayerRelation.AnyPlayer) (CounterHolder.Permanent (Filter.HasCardType CardType.Creature)) Nothing CounterGrouping.EachBatch)
      " {\"kind\":{\"type\":\"PlusOnePlusOne\"},\"motion\":{\"type\":\"Put\",\"value\":{\"type\":\"AnyPlayer\"}},\"holder\":{\"type\":\"Permanent\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"grouping\":{\"type\":\"EachBatch\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CounterTrigger.codec
