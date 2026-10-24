module Parun.Codec.BlockPermissionSpec where

import qualified Parun.Codec.BlockPermission as BlockPermission
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Aggregation as Aggregation
import qualified Parun.Types.BlockPermission as BlockPermission
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Count as Count
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.InZone as InZone
import qualified Parun.Types.PlayerRef as PlayerRef
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.Quantity as Quantity
import qualified Parun.Types.Scope as Scope
import qualified Parun.Types.Subtype as Subtype
import qualified Parun.Types.Zone as Zone

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.BlockPermission" $ do
  -- Echo Circlet's shape (CR 303.4m): the equipped creature is the one that may
  -- block one creature more than CR 509.1a allows.
  Spec.it s "MkBlockPermission" $
    Common.assertCodec
      s
      BlockPermission.codec
      (BlockPermission.MkBlockPermission Affected.Attached (Just (Quantity.Literal 1)) Nothing)
      " {\"affected\":{\"type\":\"Attached\"},\"additional\":{\"type\":\"Literal\",\"value\":1}} "
  -- Palace Guard's: "any number of creatures", an explicit null rather than an
  -- absent key.
  Spec.it s "an unbounded permission" $
    Common.assertCodec
      s
      BlockPermission.codec
      (BlockPermission.MkBlockPermission (Affected.Matching Filter.IsSource) Nothing Nothing)
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"additional\":null} "
  -- Entourage of Trest's: CR 604.2's "as long as you're the monarch" (CR 725.1).
  Spec.it s "a gated permission" $
    Common.assertCodec
      s
      BlockPermission.codec
      ( BlockPermission.MkBlockPermission
          (Affected.Matching Filter.IsSource)
          (Just (Quantity.Literal 1))
          (Just (Condition.Compares (Compares.MkCompares (Quantity.IsMonarch (PlayerRef.Relative PlayerRelation.You)) Comparison.AtLeast (Quantity.Literal 1))))
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"additional\":{\"type\":\"Literal\",\"value\":1},\"while\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"IsMonarch\",\"value\":{\"type\":\"Relative\",\"value\":{\"type\":\"You\"}}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}} "
  -- Kemba's Legion's: the arity itself is counted (CR 301.5a), so "additional"
  -- holds a whole Quantity rather than a number.
  Spec.it s "a counted permission" $
    Common.assertCodec
      s
      BlockPermission.codec
      ( BlockPermission.MkBlockPermission
          (Affected.Matching Filter.IsSource)
          ( Just
              ( Quantity.Count
                  Count.MkCount
                    { Count.scope = Scope.InZone (InZone.MkInZone Zone.Battlefield (PlayerRef.Relative PlayerRelation.AnyPlayer)),
                      Count.filter = Filter.And [Filter.HasSubtype Subtype.Equipment, Filter.IsAttachedToSource],
                      Count.aggregation = Aggregation.Members
                    }
              )
          )
          Nothing
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"additional\":{\"type\":\"Count\",\"value\":{\"aggregation\":{\"type\":\"Members\"},\"filter\":{\"type\":\"And\",\"value\":[{\"type\":\"HasSubtype\",\"value\":{\"type\":\"Equipment\"}},{\"type\":\"IsAttachedToSource\"}]},\"scope\":{\"type\":\"InZone\",\"value\":{\"zone\":{\"type\":\"Battlefield\"},\"player\":{\"type\":\"Relative\",\"value\":{\"type\":\"AnyPlayer\"}}}}}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s BlockPermission.codec
