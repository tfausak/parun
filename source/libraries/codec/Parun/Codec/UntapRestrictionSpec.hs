module Parun.Codec.UntapRestrictionSpec where

import qualified Parun.Codec.UntapRestriction as UntapRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityKind as AbilityKind
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Condition as Condition
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.UntapHold as UntapHold
import qualified Parun.Types.UntapRestriction as UntapRestriction

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.UntapRestriction" $ do
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
          Nothing
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},{\"type\":\"HasActivatedAbility\",\"value\":{\"type\":\"NonManaAbility\"}}]}}} "
  -- Amber Prison's "You may choose not to untap this artifact during your untap
  -- step" (CR 502.3): the hold is written only when it is not the default.
  Spec.it s "Elective" $
    Common.assertCodec
      s
      UntapRestriction.codec
      (UntapRestriction.MkUntapRestriction (Affected.Matching Filter.IsSource) UntapHold.Elective Nothing)
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"IsSource\"}},\"hold\":{\"type\":\"Elective\"}} "
  -- Static Orb (CR 502.3 / CR 611.3a): a cap on how many untap, in force as
  -- long as the artifact is untapped.
  Spec.it s "AtMost while" $
    Common.assertCodec
      s
      UntapRestriction.codec
      ( UntapRestriction.MkUntapRestriction
          (Affected.Matching (Filter.And []))
          (UntapHold.AtMost 2)
          (Just (Condition.All []))
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[]}},\"hold\":{\"type\":\"AtMost\",\"value\":2},\"while\":{\"type\":\"All\",\"value\":[]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s UntapRestriction.codec
