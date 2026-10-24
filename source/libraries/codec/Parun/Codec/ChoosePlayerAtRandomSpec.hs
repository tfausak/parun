module Parun.Codec.ChoosePlayerAtRandomSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ChoosePlayerAtRandom as ChoosePlayerAtRandom
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ChoosePlayerAtRandom as ChoosePlayerAtRandom
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.PlayerScope as PlayerScope
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ChoosePlayerAtRandom" $ do
  -- The two printed sentences, so the pair catches a codec that read the scope
  -- off anything but the wire.
  Spec.it s "MkChoosePlayerAtRandom, an opponent (Ruhan of the Fomori)" $
    Common.assertCodec
      s
      ChoosePlayerAtRandom.codec
      ( ChoosePlayerAtRandom.MkChoosePlayerAtRandom
          { ChoosePlayerAtRandom.scope = PlayerScope.Related PlayerRelation.Opponent,
            ChoosePlayerAtRandom.slot = SlotName.MkSlotName (Text.pack "opponent")
          }
      )
      " {\"scope\":{\"type\":\"Opponent\"},\"slot\":\"opponent\"} "
  Spec.it s "MkChoosePlayerAtRandom, a player (Strax, Sontaran Nurse)" $
    Common.assertCodec
      s
      ChoosePlayerAtRandom.codec
      ( ChoosePlayerAtRandom.MkChoosePlayerAtRandom
          { ChoosePlayerAtRandom.scope = PlayerScope.Related PlayerRelation.AnyPlayer,
            ChoosePlayerAtRandom.slot = SlotName.MkSlotName (Text.pack "chosen")
          }
      )
      " {\"scope\":{\"type\":\"AnyPlayer\"},\"slot\":\"chosen\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ChoosePlayerAtRandom.codec
