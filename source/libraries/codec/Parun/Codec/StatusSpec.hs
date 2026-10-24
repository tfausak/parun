module Parun.Codec.StatusSpec where

import qualified Parun.Codec.Status as Status
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Departure as Departure
import qualified Parun.Types.Status as Status

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Status" $ do
  Spec.it s "Playing" $
    Common.assertCodec
      s
      Status.codec
      Status.Playing
      " {\"type\":\"Playing\"} "
  -- CR 104.3: HOW the player left is part of the state, not just that they did.
  Spec.it s "Departed carries the departure" $
    Common.assertCodec
      s
      Status.codec
      (Status.Departed Departure.Conceded)
      " {\"type\":\"Departed\",\"value\":{\"type\":\"Conceded\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s Status.codec
