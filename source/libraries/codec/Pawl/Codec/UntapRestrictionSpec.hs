module Pawl.Codec.UntapRestrictionSpec where

import qualified Pawl.Codec.UntapRestriction as UntapRestriction
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.AbilityKind as AbilityKind
import qualified Pawl.Types.Affected as Affected
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.UntapHold as UntapHold
import qualified Pawl.Types.UntapRestriction as UntapRestriction

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.UntapRestriction" $ do
  -- Tsabo's Web's second sentence (CR 502.3 / CR 101.2), a PRINTED writer of
  -- Filter.HasActivatedAbility -- so this round-trips that atom in the position a
  -- card actually writes it.
  Spec.it s "MkUntapRestriction" $
    Common.assertCodec
      s
      UntapRestriction.codec
      ( UntapRestriction.MkUntapRestriction
          ( Affected.Matching
              ( Filter.And
                  [ Filter.HasCardType CardType.Land,
                    Filter.HasActivatedAbility (Just AbilityKind.NonManaAbility)
                  ]
              )
          )
          UntapHold.Forbidden
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},{\"type\":\"HasActivatedAbility\",\"value\":{\"type\":\"NonManaAbility\"}}]}}} "
  -- Amber Prison's "You may choose not to untap this artifact during your untap
  -- step" (CR 502.3): the hold is written only when it is not the default.
  Spec.it s "Elective" $
    Common.assertCodec
      s
      UntapRestriction.codec
      (UntapRestriction.MkUntapRestriction (Affected.Matching Filter.IsSource) UntapHold.Elective)
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"hold\":{\"type\":\"Elective\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s UntapRestriction.codec
