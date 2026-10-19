module Pawl.Codec.ExtraVotes where

import qualified Pawl.JsonCodec.Arm as Arm
import qualified Pawl.JsonCodec.Codec as Codec
import qualified Pawl.JsonCodec.Common as Common
import qualified Pawl.Types.ExtraVotes as ExtraVotes

codec :: Codec.Codec ExtraVotes.ExtraVotes
codec =
  Arm.tagged
    tagOf
    [ Arm.payload "Mandatory" Common.natural ExtraVotes.Mandatory (\x -> case x of ExtraVotes.Mandatory y -> Just y; _ -> Nothing),
      Arm.payload "Optional" Common.natural ExtraVotes.Optional (\x -> case x of ExtraVotes.Optional y -> Just y; _ -> Nothing)
    ]

tagOf :: ExtraVotes.ExtraVotes -> String
tagOf x = case x of
  ExtraVotes.Mandatory {} -> "Mandatory"
  ExtraVotes.Optional {} -> "Optional"
