module Parun.Codec.RangeOfInfluenceSpec where

import qualified Data.Map.Strict as Map
import qualified Parun.Codec.RangeOfInfluence as RangeOfInfluence
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.PlayerId as PlayerId
import qualified Parun.Types.RangeOfInfluence as RangeOfInfluence

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.RangeOfInfluence" $ do
  -- CR 801.1: a game not using the option.
  Spec.it s "unlimited" $
    Common.assertCodec
      s
      RangeOfInfluence.codec
      RangeOfInfluence.unlimited
      " {} "

  -- CR 801.2a: different players may have different ranges.
  Spec.it s "a range of one and a range of two" $
    Common.assertCodec
      s
      RangeOfInfluence.codec
      (RangeOfInfluence.MkRangeOfInfluence (Map.fromList [(PlayerId.MkPlayerId 0, 1), (PlayerId.MkPlayerId 1, 2)]))
      " {\"0\":1,\"1\":2} "

  Spec.it s "has a schema" $
    Common.assertHasSchema s RangeOfInfluence.codec
