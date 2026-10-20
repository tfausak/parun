module Pawl.Codec.LimitUnlessSpec where

import qualified Pawl.Codec.LimitUnless as LimitUnless
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.Compares as Compares
import qualified Pawl.Types.Comparison as Comparison
import qualified Pawl.Types.Condition as Condition
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.LimitUnless as LimitUnless
import qualified Pawl.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.LimitUnless" $ do
  -- "limit" and not "affected": a bound names no blocker, and the key set is
  -- what tells a reader of the card file which payload shape this is.
  Spec.it s "MkLimitUnless, unless elided" $
    Common.assertCodec
      s
      LimitUnless.codec
      (LimitUnless.MkLimitUnless {LimitUnless.limit = 1, LimitUnless.attackers = Nothing, LimitUnless.unless = Nothing})
      " {\"limit\":1} "
  Spec.it s "MkLimitUnless, unless written" $
    Common.assertCodec
      s
      LimitUnless.codec
      ( LimitUnless.MkLimitUnless
          { LimitUnless.limit = 2,
            LimitUnless.attackers = Nothing,
            LimitUnless.unless =
              Just $
                Condition.Compares
                  (Compares.MkCompares (Quantity.Literal 1) Comparison.AtLeast (Quantity.Literal 1))
          }
      )
      " {\"limit\":2,\"unless\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":1},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}} "
  Spec.it s "MkLimitUnless, attackers written" $
    Common.assertCodec
      s
      LimitUnless.codec
      (LimitUnless.MkLimitUnless {LimitUnless.limit = 1, LimitUnless.attackers = Just (Affected.Matching Filter.IsSource), LimitUnless.unless = Nothing})
      " {\"limit\":1,\"attackers\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LimitUnless.codec
