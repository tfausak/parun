module Parun.Codec.PileSpec where

import qualified Parun.Codec.Pile as Pile
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Pile as Pile
import qualified Parun.Types.Timestamp as Timestamp

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Pile" $ do
  -- CR 702.143e.
  Spec.it s "OfForetold" $
    Common.assertCodec
      s
      Pile.codec
      (Pile.OfForetold (Timestamp.MkTimestamp 7))
      " {\"type\":\"OfForetold\",\"value\":7} "
  -- CR 406.4.
  Spec.it s "OfFaceDown" $
    Common.assertCodec
      s
      Pile.codec
      (Pile.OfFaceDown (Timestamp.MkTimestamp 4))
      " {\"type\":\"OfFaceDown\",\"value\":4} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Pile.codec
