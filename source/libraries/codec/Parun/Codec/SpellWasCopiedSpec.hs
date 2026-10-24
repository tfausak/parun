module Parun.Codec.SpellWasCopiedSpec where

import qualified Parun.Codec.SpellWasCopied as SpellWasCopied
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.SpellWasCopied as SpellWasCopied

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SpellWasCopied" $ do
  Spec.it s "MkSpellWasCopied, both keys" $
    Common.assertCodec
      s
      SpellWasCopied.codec
      ( SpellWasCopied.MkSpellWasCopied
          { SpellWasCopied.player = PlayerId.MkPlayerId 1,
            SpellWasCopied.copy = ObjectId.MkObjectId 2
          }
      )
      " {\"player\":1,\"copy\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SpellWasCopied.codec
