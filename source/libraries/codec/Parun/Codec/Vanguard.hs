{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.Vanguard where

import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.Vanguard as Vanguard

-- | Both fields REQUIRED and neither defaulted: CR 313.6 and CR 313.7 print both
-- numbers on every vanguard card, and a zero is printed as a zero rather than
-- left off -- Gerrard's life modifier is a printed +0.
codec :: Codec.Codec Vanguard.Vanguard
codec = Fields.object $ do
  handModifier <- Fields.required "handModifier" Common.integer Vanguard.handModifier
  lifeModifier <- Fields.required "lifeModifier" Common.integer Vanguard.lifeModifier
  pure
    Vanguard.MkVanguard
      { Vanguard.handModifier = handModifier,
        Vanguard.lifeModifier = lifeModifier
      }
