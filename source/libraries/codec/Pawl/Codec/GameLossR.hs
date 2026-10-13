{-# LANGUAGE ApplicativeDo #-}

module Pawl.Codec.GameLossR where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.ControllerRelation as ControllerRelation
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.JsonCodec.Fields as Fields
import qualified Pawl.Types.GameLossR as GameLossR

-- | The effect codec is a PARAMETER, Pawl.Codec.DamageR's reason.
codec ::
  (Typeable.Typeable effect) =>
  Codec.Codec effect ->
  Codec.Codec (GameLossR.GameLossR effect)
codec effectCodec = Fields.object $ do
  whose <- Fields.required "whose" ControllerRelation.codec GameLossR.whose
  instead <- Fields.required "instead" (Common.seq effectCodec) GameLossR.instead
  pure
    GameLossR.MkGameLossR
      { GameLossR.whose = whose,
        GameLossR.instead = instead
      }
