module Pawl.Codec.TurnUpRewrite where

import qualified Data.Typeable as Typeable
import qualified Pawl.Codec.AsCopy as AsCopy
import qualified Pawl.Codec.Filter as Filter
import qualified Pawl.Codec.Keyword as Keyword
import qualified Pawl.Codec.WithCounters as WithCounters
import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.Types.TurnUpRewrite as TurnUpRewrite

-- | The ability and effect codecs are PARAMETERS, Pawl.Codec.EntryRewrite's
-- posture, for the AsCopy arm's quoted abilities and linked trigger.
codec ::
  (Typeable.Typeable ability, Eq ability, Typeable.Typeable effect, Eq effect) =>
  Codec.Codec ability ->
  Codec.Codec effect ->
  Codec.Codec (TurnUpRewrite.TurnUpRewrite ability effect)
codec abilityCodec effectCodec =
  let filterCodec = Filter.codec Keyword.codec
   in Arm.tagged
        tagOf
        [ Arm.payload "WithCounters" WithCounters.codec TurnUpRewrite.WithCounters (\x -> case x of TurnUpRewrite.WithCounters y -> Just y; _ -> Nothing),
          Arm.payload "MayAttachTo" filterCodec TurnUpRewrite.MayAttachTo (\x -> case x of TurnUpRewrite.MayAttachTo y -> Just y; _ -> Nothing),
          Arm.payload "AsCopy" (AsCopy.codec abilityCodec effectCodec) TurnUpRewrite.AsCopy (\x -> case x of TurnUpRewrite.AsCopy y -> Just y; _ -> Nothing)
        ]

tagOf :: TurnUpRewrite.TurnUpRewrite ability effect -> String
tagOf x = case x of
  TurnUpRewrite.WithCounters {} -> "WithCounters"
  TurnUpRewrite.MayAttachTo {} -> "MayAttachTo"
  TurnUpRewrite.AsCopy {} -> "AsCopy"
