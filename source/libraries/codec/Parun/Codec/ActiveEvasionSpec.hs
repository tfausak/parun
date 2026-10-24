module Parun.Codec.ActiveEvasionSpec where

import qualified Parun.Codec.ActiveEvasion as ActiveEvasion
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.ActiveEvasion as ActiveEvasion
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Expiry as Expiry
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Timestamp as Timestamp
import qualified Parun.Types.Trait as Trait

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ActiveEvasion" $ do
  -- CR 509.1b. Distinct numbers in every numeric field, so a swap cannot pass.
  Spec.it s "a class of attackers that can't be blocked" $
    Common.assertCodec
      s
      ActiveEvasion.codec
      ActiveEvasion.MkActiveEvasion
        { ActiveEvasion.source = ObjectId.MkObjectId 1,
          ActiveEvasion.controller = PlayerId.MkPlayerId 4,
          ActiveEvasion.timestamp = Timestamp.MkTimestamp 2,
          ActiveEvasion.expiry = Expiry.AtCleanup,
          ActiveEvasion.affected = Filter.HasCardType CardType.Creature,
          ActiveEvasion.blockers = Filter.Not (Filter.SharesWithSource Trait.Sector)
        }
      " {\"source\":1,\"controller\":4,\"timestamp\":2,\"expiry\":{\"type\":\"AtCleanup\"},\"affected\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"blockers\":{\"type\":\"Not\",\"value\":{\"type\":\"SharesWithSource\",\"value\":{\"type\":\"Sector\"}}}} "
  Spec.it s "has a schema" $
    Common.assertHasSchema s ActiveEvasion.codec
