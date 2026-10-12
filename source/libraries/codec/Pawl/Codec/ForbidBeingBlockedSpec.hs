module Pawl.Codec.ForbidBeingBlockedSpec where

import qualified Pawl.Codec.ForbidBeingBlocked as ForbidBeingBlocked
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Duration as Duration
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.ForbidBeingBlocked as ForbidBeingBlocked

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.ForbidBeingBlocked" $ do
  -- CR 509.1b. Three keys.
  Spec.it s "MkForbidBeingBlocked, every key" $
    Common.assertCodec
      s
      ForbidBeingBlocked.codec
      ( ForbidBeingBlocked.MkForbidBeingBlocked
          { ForbidBeingBlocked.duration = Duration.UntilEndOfTurn,
            ForbidBeingBlocked.affected = Filter.HasCardType CardType.Creature,
            ForbidBeingBlocked.blockers = Filter.Not Filter.SameSectorAsSource
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"affected\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"blockers\":{\"type\":\"Not\",\"value\":{\"type\":\"SameSectorAsSource\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ForbidBeingBlocked.codec
