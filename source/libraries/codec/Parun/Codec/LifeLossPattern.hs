{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.LifeLossPattern where

import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.Codec.LifeLossCause as LifeLossCause
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.ControllerRelation as ControllerRelation
import qualified Parun.Types.LifeLossPattern as LifeLossPattern
import qualified Parun.Types.PlayerRelation as PlayerRelation

-- | CR 109.5 reads a controller relation against the effect's source; "anyone's"
-- is the unrestricted reading, so it is what a pattern that says nothing means.
defaultWhose :: ControllerRelation.ControllerRelation
defaultWhose = ControllerRelation.Related PlayerRelation.AnyPlayer

codec :: Codec.Codec LifeLossPattern.LifeLossPattern
codec = Fields.object $ do
  whose <- Fields.defaulted "whose" defaultWhose ControllerRelation.codec LifeLossPattern.whose
  whichCause <- Fields.defaulted "whichCause" Nothing (Common.maybe LifeLossCause.codec) LifeLossPattern.whichCause
  pure
    LifeLossPattern.MkLifeLossPattern
      { LifeLossPattern.whose = whose,
        LifeLossPattern.whichCause = whichCause
      }
