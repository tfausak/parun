module Parun.Codec.LimitUnlessSpec where

import qualified Parun.Codec.LimitUnless as LimitUnless
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.LimitUnless as LimitUnless
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LimitUnless" $ do
  -- "limit" and not "affected": a bound names no blocker, and the key set is
  -- what tells a reader of the card file which payload shape this is.
  Spec.it s "MkLimitUnless, unless elided" $
    Common.assertCodec
      s
      LimitUnless.codec
      (LimitUnless.MkLimitUnless {LimitUnless.limit = 1, LimitUnless.comparison = Comparison.AtMost, LimitUnless.attackers = Nothing, LimitUnless.unless = Nothing})
      " {\"limit\":1} "
  Spec.it s "MkLimitUnless, unless written" $
    Common.assertCodec
      s
      LimitUnless.codec
      ( LimitUnless.MkLimitUnless
          { LimitUnless.limit = 2,
            LimitUnless.comparison = Comparison.AtMost,
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
      (LimitUnless.MkLimitUnless {LimitUnless.limit = 1, LimitUnless.comparison = Comparison.AtMost, LimitUnless.attackers = Just (Affected.Matching Filter.IsSource), LimitUnless.unless = Nothing})
      " {\"limit\":1,\"attackers\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  -- Phyrexian Colossus: the comparison is written once it is not AtMost.
  Spec.it s "MkLimitUnless, comparison written" $
    Common.assertCodec
      s
      LimitUnless.codec
      (LimitUnless.MkLimitUnless {LimitUnless.limit = 3, LimitUnless.comparison = Comparison.AtLeast, LimitUnless.attackers = Just (Affected.Matching Filter.IsSource), LimitUnless.unless = Nothing})
      " {\"limit\":3,\"comparison\":{\"type\":\"AtLeast\"},\"attackers\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LimitUnless.codec
