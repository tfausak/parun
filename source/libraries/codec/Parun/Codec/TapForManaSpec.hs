module Parun.Codec.TapForManaSpec where

import qualified Parun.Codec.TapForMana as TapForMana
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.ManaRestriction as ManaRestriction
import qualified Parun.Types.TapForMana as TapForMana

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.TapForMana" $ do
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
