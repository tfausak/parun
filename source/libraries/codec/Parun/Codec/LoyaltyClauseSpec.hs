module Parun.Codec.LoyaltyClauseSpec where

import qualified Parun.Codec.LoyaltyClause as LoyaltyClause
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.LoyaltyClause as LoyaltyClause

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LoyaltyClause" $ do
  Spec.it s "OncePerTurn" $
    Common.assertCodec
      s
      LoyaltyClause.codec
      LoyaltyClause.OncePerTurn
      " {\"type\":\"OncePerTurn\"} "
  Spec.it s "round trips every constructor" $ Common.assertEnumCodec s LoyaltyClause.codec
  Spec.it s "has a schema" $ Common.assertHasSchema s LoyaltyClause.codec
