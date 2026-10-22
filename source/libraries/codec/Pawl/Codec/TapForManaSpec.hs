module Pawl.Codec.TapForManaSpec where

import qualified Pawl.Codec.TapForMana as TapForMana
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Spec as Spec
import qualified Pawl.Types.CardType as CardType
import qualified Pawl.Types.Filter as Filter
import qualified Pawl.Types.ManaRestriction as ManaRestriction
import qualified Pawl.Types.TapForMana as TapForMana

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Pawl.Codec.TapForMana" $ do
  -- Piracy's: lands, and "spend this mana only to cast spells".
  Spec.it s "a restricted permission" $
    Common.assertCodec
      s
      TapForMana.codec
      ( TapForMana.MkTapForMana
          { TapForMana.permanents = Filter.HasCardType CardType.Land,
            TapForMana.restriction = Just (ManaRestriction.onlyCasts (Filter.And []))
          }
      )
      " {\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}},\"restriction\":{\"casts\":{\"type\":\"And\",\"value\":[]}}} "
  Spec.it s "omits an absent restriction" $
    Common.assertCodec
      s
      TapForMana.codec
      (TapForMana.MkTapForMana {TapForMana.permanents = Filter.HasCardType CardType.Land, TapForMana.restriction = Nothing})
      " {\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Land\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s TapForMana.codec
