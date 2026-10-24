module Parun.Codec.ManaAddedSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.ManaAdded as ManaAdded
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.ManaAdded as ManaAdded
import qualified Parun.Types.ManaAddedCause as ManaAddedCause
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaAdded" $ do
  -- Distinct numbers in the player and source keys, so a codec swapping the two
  -- would not round-trip.
  Spec.it s "MkManaAdded, every key" $
    Common.assertCodec
      s
      ManaAdded.codec
      (ManaAdded.MkManaAdded {ManaAdded.player = PlayerId.MkPlayerId 2, ManaAdded.source = ObjectId.MkObjectId 7, ManaAdded.mana = Set.fromList [ManaType.Colored Color.Red, ManaType.Colorless], ManaAdded.cause = ManaAddedCause.Resolution})
      " {\"player\":2,\"source\":7,\"mana\":[{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}},{\"type\":\"Colorless\"}],\"cause\":{\"type\":\"Resolution\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaAdded.codec
