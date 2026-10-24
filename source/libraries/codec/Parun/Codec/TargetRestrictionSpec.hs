module Parun.Codec.TargetRestrictionSpec where

import qualified Parun.Codec.TargetRestriction as TargetRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.StackObjectKind as StackObjectKind
import qualified Parun.Types.TargetRestriction as TargetRestriction

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TargetRestriction" $ do
  -- Dense Foliage's "creatures can't be the targets of spells".
  Spec.it s "MkTargetRestriction" $
    Common.assertCodec
      s
      TargetRestriction.codec
      ( TargetRestriction.MkTargetRestriction
          { TargetRestriction.affected = Affected.Matching (Filter.HasCardType CardType.Creature),
            TargetRestriction.kind = StackObjectKind.Spell
          }
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}},\"kind\":{\"type\":\"Spell\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TargetRestriction.codec
