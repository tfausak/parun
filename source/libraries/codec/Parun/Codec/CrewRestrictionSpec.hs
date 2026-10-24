module Parun.Codec.CrewRestrictionSpec where

import qualified Parun.Codec.CrewRestriction as CrewRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.CrewRestriction as CrewRestriction
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CrewRestriction" $ do
  -- Revoke Privileges' third clause (CR 702.122d / CR 101.2), written the way
  -- its own first two clauses are: an Aura's "enchanted creature" is
  -- HasAttached IsSource, Pacifism's spelling.
  Spec.it s "MkCrewRestriction" $
    Common.assertCodec
      s
      CrewRestriction.codec
      ( CrewRestriction.MkCrewRestriction
          ( Affected.Matching
              ( Filter.And
                  [ Filter.HasCardType CardType.Creature,
                    Filter.HasAttached Filter.IsSource
                  ]
              )
          )
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"HasAttached\",\"value\":{\"type\":\"IsSource\"}}]}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CrewRestriction.codec
