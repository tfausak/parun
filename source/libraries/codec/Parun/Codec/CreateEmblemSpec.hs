module Parun.Codec.CreateEmblemSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.CreateEmblem as CreateEmblem
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CreateEmblem as CreateEmblem
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

-- | The @card@ parameter is instantiated at 'Text.Text': this codec reaches it
-- only through the supplied codec, so any type proves the shape.
codec :: Codec.Codec (CreateEmblem.CreateEmblem Text.Text)
codec = CreateEmblem.codec Common.text

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CreateEmblem" $ do
  -- CR 114.2 under CR 109.5's default "you", elided: every emblem in the pool
  -- but Garruk, Apex Predator's.
  Spec.it s "MkCreateEmblem, you elided" $
    Common.assertCodec
      s
      codec
      (CreateEmblem.MkCreateEmblem (Text.pack "Emblem") (PlayerRef.Relative PlayerRelation.You))
      " {\"card\":\"Emblem\"} "
  -- Garruk, Apex Predator's "target opponent gets an emblem".
  Spec.it s "MkCreateEmblem, a target player" $
    Common.assertCodec
      s
      codec
      (CreateEmblem.MkCreateEmblem (Text.pack "Emblem") (PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target"))))
      " {\"card\":\"Emblem\",\"player\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
