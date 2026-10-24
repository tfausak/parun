{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.RevealedThisWay where

import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.RevealTiming as RevealTiming
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.RevealedThisWay as RevealedThisWay

-- | The timing is elided when absent, so Rowen's "this way" writes no key.
codec :: Codec.Codec RevealedThisWay.RevealedThisWay
codec = Fields.object $ do
  card <- Fields.required "card" (Filter.codec Keyword.codec) RevealedThisWay.card
  timing <- Fields.defaulted "timing" Nothing (Common.maybe RevealTiming.codec) RevealedThisWay.timing
  pure
    RevealedThisWay.MkRevealedThisWay
      { RevealedThisWay.card = card,
        RevealedThisWay.timing = timing
      }
