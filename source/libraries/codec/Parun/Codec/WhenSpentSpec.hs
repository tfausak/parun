module Parun.Codec.WhenSpentSpec where

import qualified Data.Text as Text
import qualified Parun.Codec.WhenSpent as WhenSpent
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AbilityName as AbilityName
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.WhenSpent as WhenSpent

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.WhenSpent" $ do
  Spec.it s "a filter and the name of the ability it arms" $
    Common.assertCodec
      s
      WhenSpent.codec
      WhenSpent.MkWhenSpent
        { WhenSpent.casts = Filter.HasCardType CardType.Instant,
          WhenSpent.ability = AbilityName.MkAbilityName (Text.pack "copy")
        }
      " {\"casts\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Instant\"}},\"ability\":\"copy\"} "
  Spec.it s "has a schema" $ Common.assertHasSchema s WhenSpent.codec
