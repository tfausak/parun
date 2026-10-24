module Parun.Codec.AffectedUnlessSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.AffectedUnless as AffectedUnless
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.AffectedUnless as AffectedUnless
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Compares as Compares
import qualified Parun.Types.Comparison as Comparison
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.Quantity as Quantity

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AffectedUnless" $ do
  -- CR 508.1c's gate absent, which is most printed restrictions: the key is
  -- omitted rather than written null.
  Spec.it s "MkAffectedUnless, unless elided" $
    Common.assertCodec
      s
      AffectedUnless.codec
      ( AffectedUnless.MkAffectedUnless
          { AffectedUnless.affected = Affected.Matching (Filter.HasCardType CardType.Creature),
            AffectedUnless.unless = Nothing,
            AffectedUnless.name = Nothing,
            AffectedUnless.amount = Nothing
          }
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}}} "
  Spec.it s "MkAffectedUnless, unless written" $
    Common.assertCodec
      s
      AffectedUnless.codec
      ( AffectedUnless.MkAffectedUnless
          { AffectedUnless.affected = Affected.Attached,
            AffectedUnless.unless =
              Just $
                Condition.Compares
                  (Compares.MkCompares (Quantity.Literal 1) Comparison.AtLeast (Quantity.Literal 1)),
            AffectedUnless.name = Nothing,
            AffectedUnless.amount = Nothing
          }
      )
      " {\"affected\":{\"type\":\"Attached\"},\"unless\":{\"type\":\"Compares\",\"value\":{\"measured\":{\"type\":\"Literal\",\"value\":1},\"comparison\":{\"type\":\"AtLeast\"},\"threshold\":{\"type\":\"Literal\",\"value\":1}}}} "
  -- CR 116.2d: the name a face gives the ability stating the restriction, which
  -- only a face granting the ignore writes (Volrath's Curse).
  Spec.it s "MkAffectedUnless, name written" $
    Common.assertCodec
      s
      AffectedUnless.codec
      ( AffectedUnless.MkAffectedUnless
          { AffectedUnless.affected = Affected.Attached,
            AffectedUnless.unless = Nothing,
            AffectedUnless.name = Just (AbilityName.MkAbilityName (Text.pack "this effect")),
            AffectedUnless.amount = Nothing
          }
      )
      " {\"affected\":{\"type\":\"Attached\"},\"name\":\"this effect\"} "
  -- CR 508.1c: the number the affected set compares against (Ensnaring Bridge).
  Spec.it s "MkAffectedUnless, amount written" $
    Common.assertCodec
      s
      AffectedUnless.codec
      ( AffectedUnless.MkAffectedUnless
          { AffectedUnless.affected = Affected.Attached,
            AffectedUnless.unless = Nothing,
            AffectedUnless.name = Nothing,
            AffectedUnless.amount = Just (Quantity.Literal 3)
          }
      )
      " {\"affected\":{\"type\":\"Attached\"},\"amount\":{\"type\":\"Literal\",\"value\":3}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s AffectedUnless.codec
