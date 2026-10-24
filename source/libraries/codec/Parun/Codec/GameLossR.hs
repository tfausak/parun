{-# LANGUAGE ApplicativeDo #-}

module Parun.Codec.GameLossR where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.ControllerRelation as ControllerRelation
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.JsonCodec.Fields as Fields
import qualified Parun.Types.GameLossR as GameLossR

-- | The effect codec is a PARAMETER, Parun.Codec.DamageR's reason.
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
