module Parun.Codec.DeciderSpec where

import qualified Parun.Codec.Decider as Decider
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Decider as Decider
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Decider" $ do
  -- A bare number, the seat's own wire form: the newtype names the ROLE and adds
  -- nothing to the payload.
  Spec.it s "the seat deciding" $
    Common.assertCodec s Decider.codec (Decider.MkDecider (PlayerId.MkPlayerId 2)) " 2 "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Decider.codec
