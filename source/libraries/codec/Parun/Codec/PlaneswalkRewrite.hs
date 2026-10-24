module Parun.Codec.PlaneswalkRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.PlaneswalkRewrite as PlaneswalkRewrite

-- | The effect codec is a PARAMETER, Parun.Codec.DamageR's reason.
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
