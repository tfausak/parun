module Parun.Codec.PhaseRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.PhaseRewrite as PhaseRewrite

codec :: (Eq effect, Typeable.Typeable effect) => Codec.Codec effect -> Codec.Codec (PhaseRewrite.PhaseRewrite effect)
codec effectCodec =
  Arm.tagged
    tagOf
    [ Arm.nullary "Skip" PhaseRewrite.Skip,
      Arm.payload "MaySkipFor" (Common.seq effectCodec) PhaseRewrite.MaySkipFor (\x -> case x of PhaseRewrite.MaySkipFor y -> Just y; _ -> Nothing)
    ]

tagOf :: PhaseRewrite.PhaseRewrite effect -> String
tagOf x = case x of
  PhaseRewrite.Skip {} -> "Skip"
  PhaseRewrite.MaySkipFor {} -> "MaySkipFor"
