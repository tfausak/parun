module Parun.Codec.SpellWasCastSpec where

import qualified Data.Set as Set
import qualified Parun.Codec.ProjectedCharacteristicsSpec as ProjectedCharacteristicsSpec
import qualified Parun.Codec.SpellWasCast as SpellWasCast
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ObjectId as ObjectId
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.SpellWasCast as SpellWasCast
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SpellWasCast" $ do
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
