module Parun.Codec.AttachRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AsCopy as AsCopy
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.AttachRewrite as AttachRewrite

-- | The ability and effect codecs are PARAMETERS, Parun.Codec.TurnUpRewrite's
-- posture, for the AsCopy arm's quoted abilities and linked trigger.
codec ::
  (Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) =>
  Codec.Codec ability ->
  Codec.Codec effect ->
  Codec.Codec (AttachRewrite.AttachRewrite ability effect)
codec abilityCodec effectCodec =
  Arm.tagged
    tagOf
    [ Arm.payload "AsCopy" (AsCopy.codec abilityCodec effectCodec) AttachRewrite.AsCopy (\x -> case x of AttachRewrite.AsCopy y -> Just y; _ -> Nothing),
      Arm.payload "ChooseColors" Common.natural AttachRewrite.ChooseColors (\x -> case x of AttachRewrite.ChooseColors y -> Just y; _ -> Nothing)
    ]

tagOf :: AttachRewrite.AttachRewrite ability effect -> String
tagOf x = case x of
  AttachRewrite.AsCopy {} -> "AsCopy"
  AttachRewrite.ChooseColors {} -> "ChooseColors"
