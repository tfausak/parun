module Parun.Codec.ForbidBeingBlockedSpec where

import qualified Parun.Codec.ForbidBeingBlocked as ForbidBeingBlocked
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Duration as Duration
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ForbidBeingBlocked as ForbidBeingBlocked
import qualified Parun.Types.Trait as Trait

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ForbidBeingBlocked" $ do
  -- CR 509.1b. Three keys.
  Spec.it s "MkForbidBeingBlocked, every key" $
    Common.assertCodec
      s
      ForbidBeingBlocked.codec
      ( ForbidBeingBlocked.MkForbidBeingBlocked
          { ForbidBeingBlocked.duration = Duration.UntilEndOfTurn,
            ForbidBeingBlocked.affected = Filter.HasCardType CardType.Creature,
            ForbidBeingBlocked.blockers = Filter.Not (Filter.SharesWithSource Trait.Sector)
          }
      )
      " {\"duration\":{\"type\":\"UntilEndOfTurn\"},\"affected\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"blockers\":{\"type\":\"Not\",\"value\":{\"type\":\"SharesWithSource\",\"value\":{\"type\":\"Sector\"}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ForbidBeingBlocked.codec
