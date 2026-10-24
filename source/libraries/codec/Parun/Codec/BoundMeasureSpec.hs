module Parun.Codec.BoundMeasureSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.BoundMeasure as BoundMeasure
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BoundMeasure as BoundMeasure
import qualified Parun.Types.Measure as Measure
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BoundMeasure" $ do
  Spec.it s "MkBoundMeasure" $
    Common.assertCodec
      s
      BoundMeasure.codec
      (BoundMeasure.MkBoundMeasure (SlotName.MkSlotName (Text.pack "thatExploitedCreature")) Measure.Toughness)
      " {\"slot\":\"thatExploitedCreature\",\"measure\":{\"type\":\"Toughness\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BoundMeasure.codec
