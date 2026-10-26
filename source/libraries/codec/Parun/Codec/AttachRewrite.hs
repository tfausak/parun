module Parun.Codec.AttachRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AsCopy as AsCopy
import qualified Parun.Codec.ChosenQuality as ChosenQuality
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
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
      Arm.payload "ChooseQuality" ChosenQuality.codec AttachRewrite.ChooseQuality (\x -> case x of AttachRewrite.ChooseQuality y -> Just y; _ -> Nothing)
    ]

tagOf :: AttachRewrite.AttachRewrite ability effect -> String
tagOf x = case x of
  AttachRewrite.AsCopy {} -> "AsCopy"
  AttachRewrite.ChooseQuality {} -> "ChooseQuality"
