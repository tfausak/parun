{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.DrawReveal where

import qualified Parun.Codec.RevealObligation as RevealObligation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.DrawReveal as DrawReveal

-- | The ordinal is elided when absent, so "each card" writes no key.
codec :: Codec.Codec DrawReveal.DrawReveal
codec = Fields.object $ do
  obligation <- Fields.required "obligation" RevealObligation.codec DrawReveal.obligation
  nth <- Fields.defaulted "nth" Nothing (Common.maybe Common.natural) DrawReveal.nth
  pure
    DrawReveal.MkDrawReveal
      { DrawReveal.obligation = obligation,
        DrawReveal.nth = nth
      }
