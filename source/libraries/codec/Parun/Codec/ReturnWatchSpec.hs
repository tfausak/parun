module Parun.Codec.ReturnWatchSpec where

import qualified Parun.Codec.ReturnWatch as ReturnWatch
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.ReturnEnding as ReturnEnding
import qualified Parun.Types.ReturnWatch as ReturnWatch
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ReturnWatch" $ do
  -- CR 610.3 as Glorious Protector prints it: a creature exiled from the
  -- battlefield, watching the permanent whose ability exiled it.
  Spec.it s "a watch on a permanent, returning to the battlefield" $
    Common.assertCodec
      s
      ReturnWatch.codec
      ReturnWatch.MkReturnWatch
        { ReturnWatch.ending = ReturnEnding.SourceLeaves (ObjectId.MkObjectId 3),
          ReturnWatch.zone = Zone.Battlefield
        }
      " {\"ending\":{\"type\":\"SourceLeaves\",\"value\":3},\"zone\":{\"type\":\"Battlefield\"}} "
  -- The zone is recorded rather than assumed, so a move out of another zone
  -- round trips as the zone it came from (CR 610.3's "previous zone").
  Spec.it s "a watch on a card that came from a graveyard" $
    Common.assertCodec
      s
      ReturnWatch.codec
      ReturnWatch.MkReturnWatch
        { ReturnWatch.ending = ReturnEnding.SourceLeaves (ObjectId.MkObjectId 7),
          ReturnWatch.zone = Zone.Graveyard
        }
      " {\"ending\":{\"type\":\"SourceLeaves\",\"value\":7},\"zone\":{\"type\":\"Graveyard\"}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ReturnWatch.codec
