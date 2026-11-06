module Parun.Codec.AmassKindSpec where

import qualified Parun.Codec.AmassKind as AmassKind
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AmassKind as AmassKind
import qualified Parun.Types.Subtype as Subtype

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AmassKind" $ do
  Spec.it s "Army" $
    Common.assertCodec
      s
      AmassKind.codec
      (AmassKind.Army Subtype.Zombie)
      " {\"type\":\"Army\",\"value\":\"Zombie\"} "
  Spec.it s "EmpowerJace" $
    Common.assertCodec
      s
      AmassKind.codec
      AmassKind.EmpowerJace
      " {\"type\":\"EmpowerJace\"} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s AmassKind.codec
