module Parun.Codec.ManaRiderSpec where

import qualified Parun.Codec.ManaRider as ManaRider
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaRider as ManaRider
import qualified Parun.Types.ManaRiderEffect as ManaRiderEffect

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.ManaRider" $ do
  -- Boseiju, Who Shelters All: the condition written out, because the printing
  -- narrows which spells the rider is about.
  Spec.it s "a condition written on the wire" $
    Common.assertCodec
      s
      ManaRider.codec
      ManaRider.MkManaRider
        { ManaRider.condition = Filter.Or [Filter.HasCardType CardType.Instant, Filter.HasCardType CardType.Sorcery],
          ManaRider.effect = ManaRiderEffect.CantBeCountered
        }
      " {\"condition\":{\"type\":\"Or\",\"value\":[{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}},{\"type\":\"HasCardType\",\"value\":{\"type\":\"Sorcery\"}}]},\"effect\":{\"type\":\"CantBeCountered\"}} "
  -- Delighted Halfling: no condition at all, which the codec reads as the
  -- trivial predicate and writes back as an absent key.
  Spec.it s "an absent condition is the trivial predicate" $
    Common.assertCodec
      s
      ManaRider.codec
      ManaRider.MkManaRider
        { ManaRider.condition = Filter.And [],
          ManaRider.effect = ManaRiderEffect.CantBeCountered
        }
      " {\"effect\":{\"type\":\"CantBeCountered\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s ManaRider.codec
