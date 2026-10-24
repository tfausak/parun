module Parun.Codec.PileDrawSpec where

import qualified Parun.Codec.PileDraw as PileDraw
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Pile as Pile
import qualified Parun.Types.PileDraw as PileDraw
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.PileDraw" $ do
  -- CR 406.4.
  Spec.it s "round-trips" $
    Common.assertCodec
      s
      PileDraw.codec
      (PileDraw.MkPileDraw {PileDraw.pile = Pile.OfFaceDown (Timestamp.MkTimestamp 4), PileDraw.ordinal = 2})
      " {\"ordinal\":2,\"pile\":{\"type\":\"OfFaceDown\",\"value\":4}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s PileDraw.codec
