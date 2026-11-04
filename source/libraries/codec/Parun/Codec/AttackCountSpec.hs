module Parun.Codec.AttackCountSpec where

import qualified Data.Either as Either
import qualified Data.Text as Text
import qualified Parun.Codec.AttackCount as AttackCount
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.AttackCount as AttackCount
import qualified Parun.Types.CardType as CardType
import qualified Parun.Types.Filter as Filter

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.AttackCount" $ do
  -- Military Intelligence's floor of two.
  Spec.it s "MkAttackCount, both keys" $
    Common.assertCodec
      s
      AttackCount.codec
      (AttackCount.MkAttackCount 2 (Filter.HasCardType CardType.Creature))
      " {\"floor\":2,\"filter\":{\"type\":\"HasCardType\",\"value\":{\"type\":\"Creature\"}}} "
  -- A zero floor is CR 508.3d's "attacks" spelled another way.
  Spec.it s "rejects a zero floor" $
    Spec.assertBool
      s
      (Either.isLeft (Codec.decode AttackCount.codec =<< Common.parse (Text.pack "{\"floor\":0,\"filter\":{\"type\":\"And\",\"value\":[]}}")))
      "expected a decode failure"
  Spec.it s "has a schema" $ Common.assertHasSchema s AttackCount.codec
