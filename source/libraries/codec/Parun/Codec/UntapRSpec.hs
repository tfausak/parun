module Parun.Codec.UntapRSpec where

import qualified Parun.Codec.UntapR as UntapR
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.BeginningStep as BeginningStep
import qualified Parun.Types.CounterKind as CounterKind
import qualified Parun.Types.Phase as Phase
import qualified Parun.Types.UntapR as UntapR
import qualified Parun.Types.UntapRewrite as UntapRewrite

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.UntapR" $ do
  -- CR 122.1d: every untap.
  Spec.it s "MkUntapR (any untap)" $
    Common.assertCodec
      s
      UntapR.codec
      (UntapR.MkUntapR {UntapR.during = Nothing, UntapR.rewrite = UntapRewrite.RemoveStunCounter})
      " {\"rewrite\":{\"type\":\"RemoveStunCounter\"}} "
  -- CR 502.3, Bewitching Leechcraft's "during your untap step".
  Spec.it s "MkUntapR (during the untap step)" $
    Common.assertCodec
      s
      UntapR.codec
      (UntapR.MkUntapR {UntapR.during = Just (Phase.Beginning BeginningStep.Untap), UntapR.rewrite = UntapRewrite.RemoveCounterToUntap CounterKind.PlusOnePlusOne})
      " {\"during\":{\"type\":\"Beginning\",\"value\":{\"type\":\"Untap\"}},\"rewrite\":{\"type\":\"RemoveCounterToUntap\",\"value\":{\"type\":\"PlusOnePlusOne\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s UntapR.codec
