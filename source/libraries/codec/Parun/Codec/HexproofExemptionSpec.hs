module Parun.Codec.HexproofExemptionSpec where

import qualified Parun.Codec.HexproofExemption as HexproofExemption
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.HexproofExemption as HexproofExemption

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.HexproofExemption" $ do
  -- Detection Tower's: creatures, and the players too.
  Spec.it s "an exemption reaching players" $
    Common.assertCodec
      s
      HexproofExemption.codec
      ( HexproofExemption.MkHexproofExemption
          { HexproofExemption.permanents = Filter.HasCardType CardType.Creature,
            HexproofExemption.players = True
          }
      )
      " {\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}},\"players\":true} "
  -- Glaring Spotlight's: creatures only.
  Spec.it s "omits players when it reaches none" $
    Common.assertCodec
      s
      HexproofExemption.codec
      (HexproofExemption.MkHexproofExemption {HexproofExemption.permanents = Filter.HasCardType CardType.Creature, HexproofExemption.players = False})
      " {\"permanents\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s HexproofExemption.codec
