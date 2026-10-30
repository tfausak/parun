module Parun.Codec.ChosenCardInHandSpec where

import qualified Parun.Codec.ChosenCardInHand as ChosenCardInHand
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.ChosenCardInHand as ChosenCardInHand
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.HowMany as HowMany
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChosenCardInHand" $ do
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
            ChosenCardInHand.count = HowMany.one
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
            ChosenCardInHand.count = HowMany.Exactly (Quantity.Literal 2)
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"filter\":{\"type\":\"And\",\"value\":[]},\"count\":{\"type\":\"Exactly\",\"value\":{\"type\":\"Literal\",\"value\":2}}} "
  -- The Great Aurora's "any number of land cards".
  Spec.it s "MkChosenCardInHand, any number" $
    Common.assertCodec
      s
      ChosenCardInHand.codec
      ( ChosenCardInHand.MkChosenCardInHand
          { ChosenCardInHand.player = PlayerRef.Relative PlayerRelation.You,
            ChosenCardInHand.filter = Filter.HasCardType CardType.Land,
            ChosenCardInHand.count = HowMany.UpTo Nothing
          }
      )
      " {\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"count\":{\"type\":\"UpTo\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChosenCardInHand.codec
