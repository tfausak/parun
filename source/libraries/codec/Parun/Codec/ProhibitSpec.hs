module Parun.Codec.ProhibitSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.Prohibit as Prohibit
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.ObjectRef as ObjectRef
import qualified Parun.Types.Prohibit as Prohibit
import qualified Parun.Types.Prohibition as Prohibition
import qualified Parun.Types.RestrictedCreatures as RestrictedCreatures
import qualified Parun.Types.SlotName as SlotName

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Prohibit" $ do
  -- CR 509.1b. Every key.
  Spec.it s "MkProhibit, every key" $
    Common.assertCodec
      s
      Prohibit.codec
      ( Prohibit.MkProhibit
          { Prohibit.what = Prohibition.Block,
            Prohibit.duration = Duration.UntilEndOfTurn,
            Prohibit.affected = RestrictedCreatures.Named (ObjectRef.InSlot (SlotName.MkSlotName (Text.pack "target")))
          }
      )
      " {\"what\":{\"type\":\"Block\"},\"duration\":{\"type\":\"UntilEndOfTurn\"},\"affected\":{\"type\":\"Named\",\"value\":{\"type\":\"InSlot\",\"value\":\"target\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Prohibit.codec
