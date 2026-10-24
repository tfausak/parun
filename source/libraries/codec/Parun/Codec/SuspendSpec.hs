module Parun.Codec.SuspendSpec where

import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.Suspend as Suspend
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.Color as Color
import qualified Parun.Types.Cost as Cost
import qualified Parun.Types.Keyword as Keyword
import qualified Parun.Types.ManaCost as ManaCost
import qualified Parun.Types.ManaSymbol as ManaSymbol
import qualified Parun.Types.ManaType as ManaType
import qualified Parun.Types.Suspend as Suspend
import qualified Parun.Types.SuspendCounters as SuspendCounters

-- | Instantiated at 'Keyword.Keyword', the only concrete instantiation anywhere
-- in the pool.
codec :: Codec.Codec (Suspend.Suspend Keyword.Keyword)
codec = Suspend.codec Keyword.codec

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.Suspend" $ do
  -- CR 702.62a: Rift Bolt's "Suspend 1--{R}".
  Spec.it s "MkSuspend" $
    Common.assertCodec
      s
      codec
      ( Suspend.MkSuspend
          { Suspend.counters = SuspendCounters.Literal 1,
            Suspend.cost = Cost.MkCost {Cost.mana = Just (ManaCost.MkManaCost [ManaSymbol.OfType (ManaType.Colored Color.Red)]), Cost.components = []}
          }
      )
      " {\"counters\":{\"type\":\"Literal\",\"value\":1},\"cost\":{\"mana\":[{\"type\":\"OfType\",\"value\":{\"type\":\"Colored\",\"value\":{\"type\":\"Red\"}}}]}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s codec
