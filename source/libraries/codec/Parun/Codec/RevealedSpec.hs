module Parun.Codec.RevealedSpec where

import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.Codec.Revealed as Revealed
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RevealCause as RevealCause
import qualified Parun.Types.Revealed as Revealed

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Revealed" $ do
  -- CR 701.20a through CR 702.94a's miracle reveal.
  Spec.it s "MkRevealed, every key" $
    Common.assertCodec
      s
      Revealed.codec
      ( Revealed.MkRevealed
          { Revealed.player = PlayerId.MkPlayerId 0,
            Revealed.card = ObjectId.MkObjectId 7,
            Revealed.cause = RevealCause.ForMiracle (Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost []), Cost.components = []}),
            Revealed.characteristics = ProjectedCharacteristicsSpec.testCharacteristics
          }
      )
      ( "{\"player\":0,\"card\":7,\"cause\":{\"type\":\"ForMiracle\",\"value\":{\"mana\":[]}},\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> "}"
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s Revealed.codec
