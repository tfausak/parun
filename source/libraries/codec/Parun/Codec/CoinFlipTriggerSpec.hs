module Parun.Codec.CoinFlipTriggerSpec where

import qualified Parun.Codec.CoinFlipTrigger as CoinFlipTrigger
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Spec as Spec
import qualified Parun.Types.CoinFlipTrigger as CoinFlipTrigger
import qualified Parun.Types.FlipOutcome as FlipOutcome
import qualified Parun.Types.PlayerRelation as PlayerRelation

spec :: (Monad m, Monad n) => Spec.Spec m n -> n ()
spec s = Spec.describe s "Parun.Codec.CoinFlipTrigger" $ do
  -- Karplusan Minotaur's "whenever you lose a coin flip".
  Spec.it s "round-trips both keys" $
    Common.assertCodec
      s
      CoinFlipTrigger.codec
      (CoinFlipTrigger.MkCoinFlipTrigger PlayerRelation.You FlipOutcome.Lost)
      " {\"player\":{\"type\":\"You\"},\"outcome\":{\"type\":\"Lost\"}} "
  Spec.it s "has a schema" $ Common.assertHasSchema s CoinFlipTrigger.codec
