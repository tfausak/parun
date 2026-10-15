module Pawl.Codec.PlaneswalkRewrite where

import qualified Data.Typeable as Typeable
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.PlaneswalkRewrite as PlaneswalkRewrite

-- | The effect codec is a PARAMETER, Pawl.Codec.DamageR's reason.
codec ::
  (Typeable.Typeable effect, Eq effect) =>
  Codec.Codec effect ->
  Codec.Codec (PlaneswalkRewrite.PlaneswalkRewrite effect)
codec effectCodec =
  Arm.tagged
    tagOf
    [ Arm.nullary "ArrangeTopTwo" PlaneswalkRewrite.ArrangeTopTwo,
      Arm.payload "RunEffects" (Common.seq effectCodec) PlaneswalkRewrite.RunEffects (\x -> case x of PlaneswalkRewrite.RunEffects y -> Just y; _ -> Nothing)
    ]

tagOf :: PlaneswalkRewrite.PlaneswalkRewrite effect -> String
tagOf x = case x of
  PlaneswalkRewrite.ArrangeTopTwo {} -> "ArrangeTopTwo"
  PlaneswalkRewrite.RunEffects {} -> "RunEffects"
