{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.BattlefieldCandidate where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.PlayerId as PlayerId
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.BattlefieldCandidate as BattlefieldCandidate

-- | The codec for what rides beside the controller is a PARAMETER, since the
-- type is parametric in it -- the same shape Parun.Codec.Divided uses for its
-- quantity.
codec :: (Typeable.Typeable a) => Codec.Codec a -> Codec.Codec (BattlefieldCandidate.BattlefieldCandidate a)
codec inner = Fields.object $ do
  controller <- Fields.required "controller" PlayerId.codec BattlefieldCandidate.controller
  characteristics <- Fields.required "characteristics" inner BattlefieldCandidate.characteristics
  pure
    BattlefieldCandidate.MkBattlefieldCandidate
      { BattlefieldCandidate.controller = controller,
        BattlefieldCandidate.characteristics = characteristics
      }
