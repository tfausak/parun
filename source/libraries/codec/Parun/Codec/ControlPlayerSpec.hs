module Parun.Codec.ControlPlayerSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.ControlPlayer as ControlPlayer
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlPlayer as ControlPlayer
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControlPlayer" $ do
  Spec.it s "MkControlPlayer, restriction elided" $
    Common.assertCodec
      s
      ControlPlayer.codec
      ( ControlPlayer.MkControlPlayer
          { ControlPlayer.slot = SlotName.MkSlotName (Text.pack "target"),
            ControlPlayer.manaFromLandsOnly = False
          }
      )
      " {\"slot\":\"target\"} "
  -- Word of Command's clause, and the only producer that writes the key.
  Spec.it s "MkControlPlayer, restriction written" $
    Common.assertCodec
      s
      ControlPlayer.codec
      ( ControlPlayer.MkControlPlayer
          { ControlPlayer.slot = SlotName.MkSlotName (Text.pack "opponent"),
            ControlPlayer.manaFromLandsOnly = True
          }
      )
      " {\"slot\":\"opponent\",\"manaFromLandsOnly\":true} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ControlPlayer.codec
