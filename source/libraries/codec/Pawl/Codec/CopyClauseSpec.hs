module Pawl.Codec.CopyClauseSpec where

import qualified Data.Set as Set
import qualified Pawl.Codec.CopyClause as CopyClause
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Color as Color
import qualified Pawl.Types.Compares as Compares
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.CopyClause as CopyClause
import qualified Pawl.Types.CopyException as CopyException
import qualified Pawl.Types.CounterKind as CounterKind
import qualified Pawl.Types.Designation as Designation
import qualified Pawl.Types.Quantity as Quantity
import qualified Pawl.Types.SetPowerToughness as SetPowerToughness
import qualified Pawl.Types.WithCounters as WithCounters

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.CopyClause" $ do
  -- CR 707.9b: Quicksilver Gargantuan's unconditional "except it's 7/7", the
  -- condition and counters keys defaulted away.
  Spec.it s "MkCopyClause, unconditional exceptions" $
    Common.assertCodec
      s
      (CopyClause.codec Common.text)
      (CopyClause.MkCopyClause Nothing [CopyException.SetPowerToughness (SetPowerToughness.MkSetPowerToughness 7 7)] Nothing)
      " {\"exceptions\":[{\"type\":\"SetPowerToughness\",\"value\":{\"power\":7,\"toughness\":7}}]} "
  -- CR 707.9e: Altered Ego's counters alone.
  Spec.it s "MkCopyClause, unconditional counters" $
    Common.assertCodec
      s
      (CopyClause.codec Common.text)
      (CopyClause.MkCopyClause Nothing [] (Just (WithCounters.one CounterKind.PlusOnePlusOne (Quantity.Literal 1))))
      " {\"counters\":[{\"kind\":{\"type\":\"PlusOnePlusOne\"},\"count\":{\"type\":\"Literal\",\"value\":1}}]} "
  -- CR 707.9f: Vizier of Many Faces' colour, under its embalmed condition.
  Spec.it s "MkCopyClause, a condition" $
    Common.assertCodec
      s
      (CopyClause.codec Common.text)
      (CopyClause.MkCopyClause (Just (Condition.Compares (Compares.MkCompares (Quantity.HasDesignation Designation.Embalmed) Comparison.AtLeast (Quantity.Literal 1)))) [CopyException.SetColors (Set.singleton Color.White)] Nothing)
      " {\"condition\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"HasDesignation\",\"value\":{\"type\":\"Embalmed\"}},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}},\"exceptions\":[{\"type\":\"SetColors\",\"value\":[{\"type\":\"White\"}]}]} "
  Spec.it s "has a schema" $ Common.assertHasSchema s (CopyClause.codec Common.text)
