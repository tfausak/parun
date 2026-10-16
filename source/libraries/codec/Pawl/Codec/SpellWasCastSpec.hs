module Pawl.Codec.SpellWasCastSpec where

import qualified Data.Set as Set
import qualified Pawl.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Pawl.Codec.SpellWasCast as SpellWasCast
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Compares as Compares
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.Keyword as Keyword
import qualified Pawl.Types.ObjectId as ObjectId
import qualified Pawl.Types.PlayerId as PlayerId
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SpellWasCast as SpellWasCast
import qualified Pawl.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.SpellWasCast" $ do
  -- CR 601.2i, with the stack object's characteristics as of the cast.
  Spec.it s "MkSpellWasCast, every key" $
    Common.assertCodec
      s
      SpellWasCast.codec
      ( SpellWasCast.MkSpellWasCast
          { SpellWasCast.player = PlayerId.MkPlayerId 0,
            SpellWasCast.spell = ObjectId.MkObjectId 7,
            SpellWasCast.characteristics = ProjectedCharacteristicsSpec.testCharacteristics,
            SpellWasCast.zone = Just Zone.Hand,
            SpellWasCast.castUsing = Just Keyword.JumpStart,
            SpellWasCast.lapsedGrants = Set.singleton (Condition.Compares (Compares.MkCompares (Quantity.Literal 3) Comparison.AtLeast (Quantity.Literal 5)))
          }
      )
      ( "{\"player\":0,\"spell\":7,\"characteristics\":"
          <> ProjectedCharacteristicsSpec.testCharacteristicsJson
          <> ",\"zone\":{\"type\":\"Hand\"},\"castUsing\":{\"type\":\"JumpStart\"},\"lapsedGrants\":[{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":3},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":5}}}]}"
      )
  Spec.it s "has a schema" $ Common.assertHasSchema s SpellWasCast.codec
