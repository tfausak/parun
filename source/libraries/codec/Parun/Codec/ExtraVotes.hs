module Parun.Codec.ExtraVotes where

import qualified Parun.JsonCodec.Arm as Arm
import qualified Parun.JsonCodec.Codec as Codec
import qualified Parun.JsonCodec.Common as Common
import qualified Parun.Types.ExtraVotes as ExtraVotes

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
