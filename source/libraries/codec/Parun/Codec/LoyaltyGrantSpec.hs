module Parun.Codec.LoyaltyGrantSpec where

import qualified Parun.Codec.LoyaltyGrant as LoyaltyGrant
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Filter as Filter
import qualified Parun.Types.LoyaltyClause as LoyaltyClause
import qualified Parun.Types.LoyaltyGrant as LoyaltyGrant

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.LoyaltyGrant" $ do
  -- The Wandering Emperor's own.
  Spec.it s "a Window grant" $
    Common.assertCodec
      s
      LoyaltyGrant.codec
      (LoyaltyGrant.MkLoyaltyGrant {LoyaltyGrant.relaxes = LoyaltyClause.Window, LoyaltyGrant.permanents = Filter.IsSource})
      " {\"relaxes\":{\"type\":\"Window\"},\"permanents\":{\"type\":\"IsSource\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s LoyaltyGrant.codec
