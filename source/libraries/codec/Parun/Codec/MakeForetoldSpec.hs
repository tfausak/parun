module Parun.Codec.MakeForetoldSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.MakeForetold as MakeForetold
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.MakeForetold as MakeForetold
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MakeForetold" $ do
  -- CR 702.143d's first sentence alone (The Foretold Soldier), which is what a
  -- card file that omits the cost gets.
  Spec.it s "the cards, with CR 702.143d's cost absent" $
    Common.assertCodec
      s
      MakeForetold.codec
      MakeForetold.MkMakeForetold
        { MakeForetold.cards = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "foretold")),
          MakeForetold.manaCostReducedBy = Nothing
        }
      " {\"cards\":{\"type\":\"InSlot\",\"value\":\"foretold\"}} "
  -- Ethereal Valkyrie's "its foretell cost is its mana cost reduced by {2}".
  Spec.it s "the granted cost round-trips when it is stated" $
    Common.assertCodec
      s
      MakeForetold.codec
      MakeForetold.MkMakeForetold
        { MakeForetold.cards = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "foretold")),
          MakeForetold.manaCostReducedBy = Just (ManaCost.MkManaCost [ManaSymbol.Generic 2])
        }
      " {\"cards\":{\"type\":\"InSlot\",\"value\":\"foretold\"},\"manaCostReducedBy\":[{\"type\":\"Generic\",\"value\":2}]} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s MakeForetold.codec
