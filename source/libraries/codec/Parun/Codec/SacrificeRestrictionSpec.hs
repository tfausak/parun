module Parun.Codec.SacrificeRestrictionSpec where

import qualified Parun.Codec.SacrificeRestriction as SacrificeRestriction
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Affected as Affected
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.PlayerRelation as PlayerRelation
import qualified Parun.Types.SacrificeRestriction as SacrificeRestriction

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.SacrificeRestriction" $ do
  -- Garland, Royal Kidnapper's third clause (CR 701.21a / CR 101.2), which is
  -- also the one Affected in the pool that conjoins CR 109.5's controller with
  -- CR 108.3's owner -- so this round-trips the OwnedBy atom in the position a
  -- card actually writes it, not only as a bare filter.
  Spec.it s "MkSacrificeRestriction" $
    Common.assertCodec
      s
      SacrificeRestriction.codec
      ( SacrificeRestriction.MkSacrificeRestriction
          ( Affected.Matching
              ( Filter.And
                  [ Filter.HasCardType CardType.Creature,
                    Filter.ControlledBy PlayerRelation.You,
                    Filter.Not (Filter.OwnedBy PlayerRelation.You)
                  ]
              )
          )
      )
      " {\"affected\":{\"type\":\"Matching\",\"value\":{\"type\":\"And\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},{\"type\":\"ControlledBy\",\"value\":{\"type\":\"You\"}},{\"type\":\"Not\",\"value\":{\"type\":\"OwnedBy\",\"value\":{\"type\":\"You\"}}}]}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s SacrificeRestriction.codec
