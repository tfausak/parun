module Parun.Codec.RepeatSpec where

import qualified Data.Sequence as Seq
import qualified Data.Text as Text
import qualified Parun.Codec.Repeat as Repeat
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Repeat as Repeat
import qualified Parun.Types.SlotName as SlotName

-- | Instantiated at 'Text.Text' for Parun.Codec.ForEachSpec's reason.
codec :: Codec.Codec (Repeat.Repeat Text.Text)
codec = Repeat.codec Common.text

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Repeat" $ do
  -- Trade Secrets' shape: the target opponent chooses.
  Spec.it s "MkRepeat" $
    Common.assertCodec
      s
      codec
      ( Repeat.MkRepeat
          { Repeat.chooser = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            Repeat.body = Seq.fromList [Text.pack "they draw", Text.pack "you draw"],
            Repeat.gate = Nothing
          }
      )
      " {\"chooser\":{\"type\":\"InSlot\",\"value\":\"target\"},\"body\":[\"they draw\",\"you draw\"]} "
  -- Delina, Wild Mage's shape: asked only on a roll of 15 or more.
  Spec.it s "MkRepeat with a gate" $
    Common.assertCodec
      s
      codec
      ( Repeat.MkRepeat
          { Repeat.chooser = PlayerRef.Relative PlayerRelation.You,
            Repeat.body = Seq.fromList [Text.pack "roll", Text.pack "copy"],
            Repeat.gate = Just (Condition.Compares (Compares.MkCompares (Quantity.InSlot (SlotName.MkSlotName (Text.pack "result"))) Comparison.AtLeast (Quantity.Literal 15)))
          }
      )
      " {\"chooser\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}},\"body\":[\"roll\",\"copy\"],\"gate\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"InSlot\",\"value\":\"result\"},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":15}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
