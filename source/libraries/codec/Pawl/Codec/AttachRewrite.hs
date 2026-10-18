module Pawl.Codec.AttachRewrite where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.AsCopy as AsCopy
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.AttachRewrite as AttachRewrite

-- | The ability and effect codecs are PARAMETERS, Pawl.Codec.TurnUpRewrite's
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
