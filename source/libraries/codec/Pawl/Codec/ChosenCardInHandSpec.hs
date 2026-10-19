module Pawl.Codec.ChosenCardInHandSpec where

import qualified Pawl.Codec.ChosenCardInHand as ChosenCardInHand
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.ChosenCardInHand as ChosenCardInHand
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.PlayerRef as PlayerRef
import qualified Pawl.Types.PlayerRelation as PlayerRelation
import qualified Pawl.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ChosenCardInHand" $ do
  -- Elvish Piper's "a creature card from your hand": CR 402.3 makes the one
  -- PlayerRef both the chooser and the hand, and the Filter is what narrows the
  -- offer.
  Spec.it s "MkChosenCardInHand, the singular count elided" $
    Common.assertCodec
      s
      ChosenCardInHand.codec
      ( ChosenCardInHand.MkChosenCardInHand
          { ChosenCardInHand.player = PlayerRef.Relative PlayerRelation.You,
            ChosenCardInHand.filter = Filter.HasCardType CardType.Creature,
            ChosenCardInHand.count = Quantity.Literal 1
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- Aquatic Subtlety's "two cards from your hand".
  Spec.it s "MkChosenCardInHand, a count of two" $
    Common.assertCodec
      s
      ChosenCardInHand.codec
      ( ChosenCardInHand.MkChosenCardInHand
          { ChosenCardInHand.player = PlayerRef.Relative PlayerRelation.You,
            ChosenCardInHand.filter = Filter.And [],
            ChosenCardInHand.count = Quantity.Literal 2
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"filter\":{\"type\":\"And\",\"value\":[]},\"count\":{\"type\":\"Literal\",\"value\":2}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChosenCardInHand.codec
