module Parun.Codec.GainControlSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.GainControl as GainControl
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.GainControl as GainControl
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.GainControl" $ do
  Spec.it s "MkGainControl, to the effect's controller elided" $
    Common.assertCodec
      s
      GainControl.codec
      ( GainControl.MkGainControl
          { GainControl.duration = Duration.UntilEndOfTurn,
            GainControl.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            GainControl.to = PlayerRef.Relative PlayerRelation.You
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "MkGainControl, to a named player" $
    Common.assertCodec
      s
      GainControl.codec
      ( GainControl.MkGainControl
          { GainControl.duration = Duration.Indefinite,
            GainControl.ref = ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            GainControl.to = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "teammate"))
          }
      )
      " {\"duration\":{\"type\":\"Indefinite\"},\"ref\":{\"type\":\"InSlot\",\"value\":\"target\"},\"to\":{\"type\":\"InSlot\",\"value\":\"teammate\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s GainControl.codec
