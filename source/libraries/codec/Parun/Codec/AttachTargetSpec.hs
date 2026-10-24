module Parun.Codec.AttachTargetSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.AttachTarget as AttachTarget
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttachTarget as AttachTarget
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttachTarget" $ do
  -- CR 701.3: attach the slot's object to a permanent matching the filter.
  Spec.it s "MkAttachTarget, both keys" $
    Common.assertCodec
      s
      AttachTarget.codec
      ( AttachTarget.MkAttachTarget
          { AttachTarget.slot = SlotName.MkSlotName (Text.pack "target"),
            AttachTarget.filter = Filter.HasCardType CardType.Creature
          }
      )
      " {\"slot\":\"target\",\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AttachTarget.codec
