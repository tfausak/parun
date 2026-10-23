module Pawl.Codec.TargetRestrictionSpec where

import qualified Pawl.Codec.TargetRestriction as TargetRestriction
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.StackObjectKind as StackObjectKind
import qualified Pawl.Types.TargetRestriction as TargetRestriction

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TargetRestriction" $ do
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
