module Parun.Codec.FightSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Fight as Fight
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Fight as Fight
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Fight" $ do
  -- Prey Upon's two slots, in the order the object keys sort rather than the
  -- order the card's sentence names them.
  Spec.it s "MkFight, both slots" $
    Common.assertCodec
      s
      Fight.codec
      (Fight.MkFight (SlotName.MkSlotName (Text.pack "mine")) (SlotName.MkSlotName (Text.pack "theirs")))
      " {\"first\":\"mine\",\"second\":\"theirs\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Fight.codec
