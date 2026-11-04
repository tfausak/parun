module Parun.Codec.TraitSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.Trait as Trait
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Trait as Trait

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Trait" $ do
  Spec.it s "Sector" $
    Common.assertCodec
      s
      Trait.codec
      Trait.Sector
      " {\"type\":\"Sector\"} "
  Spec.it s "Color" $ Common.assertCodec s Trait.codec Trait.Color " {\"type\":\"Color\"} "
  Spec.it s "Name" $ Common.assertCodec s Trait.codec Trait.Name " {\"type\":\"Name\"} "
  Spec.it s "Owner" $ Common.assertCodec s Trait.codec Trait.Owner " {\"type\":\"Owner\"} "
  Spec.it s "Controller" $ Common.assertCodec s Trait.codec Trait.Controller " {\"type\":\"Controller\"} "
  Spec.it s "CreatureType" $ Common.assertCodec s Trait.codec Trait.CreatureType " {\"type\":\"CreatureType\"} "
  Spec.it s "CardType, any" $ Common.assertCodec s Trait.codec (Trait.CardType Nothing) " {\"type\":\"CardType\"} "
  Spec.it s "CardType, among some" $
    Common.assertCodec
      s
      Trait.codec
      (Trait.CardType (Just (Set.fromList [CardType.Artifact, CardType.Land])))
      " {\"type\":\"CardType\",\"value\":[{\"type\":\"Artifact\"},{\"type\":\"Land\"}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s Trait.codec
