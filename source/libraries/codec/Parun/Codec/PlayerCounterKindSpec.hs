module Parun.Codec.PlayerCounterKindSpec where

import qualified Parun.Codec.PlayerCounterKind as PlayerCounterKind
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerCounterKind as PlayerCounterKind

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PlayerCounterKind" $ do
  Spec.it s "Energy" $
    Common.assertCodec
      s
      PlayerCounterKind.codec
      PlayerCounterKind.Energy
      " {\"type\":\"Energy\"} "
  Spec.it s "Ticket" $
    Common.assertCodec
      s
      PlayerCounterKind.codec
      PlayerCounterKind.Ticket
      " {\"type\":\"Ticket\"} "
  Spec.it s "Poison" $
    Common.assertCodec
      s
      PlayerCounterKind.codec
      PlayerCounterKind.Poison
      " {\"type\":\"Poison\"} "
  Spec.it s "Rad" $
    Common.assertCodec
      s
      PlayerCounterKind.codec
      PlayerCounterKind.Rad
      " {\"type\":\"Rad\"} "
  Spec.it s "Experience" $
    Common.assertCodec
      s
      PlayerCounterKind.codec
      PlayerCounterKind.Experience
      " {\"type\":\"Experience\"} "
  -- Exhaustive where the literals above are representative: Arm.enum derives
  -- the arm list from the type, so this is what would catch a constructor the
  -- derivation missed or two that encode alike.
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s PlayerCounterKind.codec
  Spec.it s "has a schema" $
    Common.assertHasSchema s PlayerCounterKind.codec
