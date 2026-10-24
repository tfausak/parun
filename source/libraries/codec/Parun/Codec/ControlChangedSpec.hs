module Parun.Codec.ControlChangedSpec where

import qualified Parun.Codec.ControlChanged as ControlChanged
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ControlChanged as ControlChanged
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ControlChanged" $ do
  -- CR 613.1b. BEFORE and AFTER are both a PlayerId and deliberately differ --
  -- Parun.Engine.Engine.sampleControl only mints the event when they do, and a
  -- symmetric fixture would round-trip a codec that reported the change
  -- backwards.
  Spec.it s "MkControlChanged, every key" $
    Common.assertCodec
      s
      ControlChanged.codec
      ( ControlChanged.MkControlChanged
          { ControlChanged.object = ObjectId.MkObjectId 1,
            ControlChanged.before = PlayerId.MkPlayerId 0,
            ControlChanged.after = PlayerId.MkPlayerId 1
          }
      )
      " {\"object\":1,\"before\":0,\"after\":1} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ControlChanged.codec
