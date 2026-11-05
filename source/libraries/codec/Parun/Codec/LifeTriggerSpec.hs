module Parun.Codec.LifeTriggerSpec where

import qualified Parun.Codec.LifeTrigger as LifeTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Batching as Batching
import qualified Parun.Types.LifeDirection as LifeDirection
import qualified Parun.Types.LifeTrigger as LifeTrigger
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.TriggerFrequency as TriggerFrequency
import qualified Parun.Types.TurnScope as TurnScope

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LifeTrigger" $ do
  -- Vengeful Warchief.
  Spec.it s "FirstTimeEachTurn writes its key" $
    Common.assertCodec
      s
      LifeTrigger.codec
      (LifeTrigger.MkLifeTrigger LifeDirection.Lost PlayerRelation.You (TurnScope.PlayersTurn (PlayerRef.Relative PlayerRelation.AnyPlayer)) Batching.EachOccurrence TriggerFrequency.FirstTimeEachTurn)
      " {\"direction\":{\"type\":\"Lost\"},\"player\":{\"type\":\"You\"},\"frequency\":{\"type\":\"FirstTimeEachTurn\"}} "
  -- Exquisite Blood: every loss, on any turn, once each, so no defaulted key.
  Spec.it s "the defaults write no key" $
    Common.assertCodec
      s
      LifeTrigger.codec
      (LifeTrigger.MkLifeTrigger LifeDirection.Lost PlayerRelation.Opponent (TurnScope.PlayersTurn (PlayerRef.Relative PlayerRelation.AnyPlayer)) Batching.EachOccurrence TriggerFrequency.EveryTime)
      " {\"direction\":{\"type\":\"Lost\"},\"player\":{\"type\":\"Opponent\"}} "
  -- Synthetic Communal Vigil's "one or more players gain life".
  Spec.it s "OneOrMore writes its key" $
    Common.assertCodec
      s
      LifeTrigger.codec
      (LifeTrigger.MkLifeTrigger LifeDirection.Gained PlayerRelation.AnyPlayer (TurnScope.PlayersTurn (PlayerRef.Relative PlayerRelation.AnyPlayer)) Batching.OneOrMore TriggerFrequency.EveryTime)
      " {\"direction\":{\"type\":\"Gained\"},\"player\":{\"type\":\"AnyPlayer\"},\"batching\":{\"type\":\"OneOrMore\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LifeTrigger.codec
