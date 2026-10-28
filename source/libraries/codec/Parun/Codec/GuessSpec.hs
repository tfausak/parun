module Parun.Codec.GuessSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Guess as Guess
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChosenCardInHand as ChosenCardInHand
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Guess as Guess
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.Measures as Measures
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Operand as Operand
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Guess" $ do
  -- Master of Predicaments' "choose a card in your hand. That player guesses
  -- whether the card's mana value is greater than 4".
  Spec.it s "MkGuess" $
    Common.assertCodec
      s
      Guess.codec
      Guess.MkGuess
        { Guess.subject = ObjectRef.ChosenCardInHand (ChosenCardInHand.MkChosenCardInHand (PlayerRef.Relative PlayerRelation.You) (Filter.And []) (Quantity.Literal 1)),
          Guess.slot = SlotName.MkSlotName (Text.pack "chosen"),
          Guess.guesser = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "thatPlayer")),
          Guess.proposition = Filter.Measures (Measures.MkMeasures Measure.ManaValue Comparison.GreaterThan (Operand.Literal 4)),
          Guess.right = SlotName.MkSlotName (Text.pack "right")
        }
      " {\"guesser\":{\"type\":\"InSlot\",\"value\":\"thatPlayer\"},\"proposition\":{\"type\":\"Measures\",\"value\":{\"comparison\":{\"type\":\"GreaterThan\"},\"measure\":{\"type\":\"ManaValue\"},\"operand\":{\"type\":\"Literal\",\"value\":4}}},\"right\":\"right\",\"slot\":\"chosen\",\"subject\":{\"type\":\"ChosenCardInHand\",\"value\":{\"filter\":{\"type\":\"And\",\"value\":[]},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Guess.codec
