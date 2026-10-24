module Parun.Codec.SacrificeToEnterSpec where

import qualified Parun.Codec.SacrificeToEnter as SacrificeToEnter
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.SacrificeToEnter as SacrificeToEnter
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SacrificeToEnter" $ do
  Spec.it s "MkSacrificeToEnter" $
    Common.assertCodec
      s
      SacrificeToEnter.codec
      ( SacrificeToEnter.MkSacrificeToEnter
          { SacrificeToEnter.count = 1,
            SacrificeToEnter.filter = Filter.HasSubtype Subtype.Forest
          }
      )
      " {\"count\":1,\"filter\":{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Forest\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SacrificeToEnter.codec
