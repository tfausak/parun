module Parun.Codec.TurnUpRewrite where

import qualified Data.Typeable as Typeable
import qualified Parun.Codec.AsCopy as AsCopy
import qualified Parun.Codec.Filter as Filter
import qualified Parun.Codec.Keyword as Keyword
import qualified Parun.Codec.WithCounters as WithCounters
import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.Types.TurnUpRewrite as TurnUpRewrite

-- | The ability and effect codecs are PARAMETERS, Parun.Codec.EntryRewrite's
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
