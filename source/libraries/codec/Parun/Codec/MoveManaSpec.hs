module Parun.Codec.MoveManaSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.MoveMana as MoveMana
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.MoveMana as MoveMana
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.MoveMana" $ do
  -- CR 106.13: the loser and the gainer, spelled the same way -- Drain Power's
  -- "that player loses all unspent mana and you add the mana lost this way".
  Spec.it s "MkMoveMana, both keys" $
    Common.assertCodec
      s
      MoveMana.codec
      ( MoveMana.MkMoveMana
          { MoveMana.from = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            MoveMana.to = Just (PlayerRef.Relative PlayerRelation.You)
          }
      )
      " {\"from\":{\"type\":\"InSlot\",\"value\":\"target\"},\"to\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}} "
  -- CR 106.4: Mana Short's "that player loses all unspent mana", no one adding it.
  Spec.it s "MkMoveMana, no to" $
    Common.assertCodec
      s
      MoveMana.codec
      ( MoveMana.MkMoveMana
          { MoveMana.from = PlayerRef.InSlot (SlotName.MkSlotName (Text.pack "target")),
            MoveMana.to = Nothing
          }
      )
      " {\"from\":{\"type\":\"InSlot\",\"value\":\"target\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s MoveMana.codec
