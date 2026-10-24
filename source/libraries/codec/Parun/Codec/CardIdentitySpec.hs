module Parun.Codec.CardIdentitySpec where

import qualified Parun.Codec.CardIdentity as CardIdentity
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardIdentity as CardIdentity
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CardIdentity" $ do
  Spec.it s "MkCardIdentity, every key" $
    Common.assertCodec
      s
      CardIdentity.codec
      ( CardIdentity.MkCardIdentity
          { CardIdentity.serial = 4,
            CardIdentity.startingOwner = PlayerId.MkPlayerId 2
          }
      )
      " {\"serial\":4,\"startingOwner\":2} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CardIdentity.codec
